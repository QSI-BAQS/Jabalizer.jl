use std::{
    cmp,
    collections::HashMap,
    ffi::OsString,
    fs::File,
    io::Write,
    path::Path,
    sync::{
        mpsc,
        Arc,
        Mutex,
    },
    time::Instant,
};

use anyhow::{
    Context,
    Result,
};
use pauli_tracker::{
    collection::{
        Iterable,
        Map,
    },
    pauli::{
        PauliStack,
        PauliTuple,
    },
    scheduler::{
        space::{
            Graph,
            GraphBuffer,
        },
        time::{
            DependencyBuffer,
            Partitioner,
            PathGenerator,
        },
        tree::{
            Focus,
            FocusIterator,
            Step,
        },
        Scheduler,
    },
    tracker::frames::{
        self,
        dependency_graph,
    },
};
use scoped_threadpool::Pool;
use serde::{
    Deserialize,
    Serialize,
};

use crate::cli;

type Frames = frames::Frames<Map<PauliStack<Vec<bool>>>>;
type Gates = Vec<(String, usize)>;
type Measurements = Vec<(String, usize, isize)>;
type OnePath = Vec<Vec<usize>>;
type SparseGraph = Vec<Vec<usize>>;
type Paths = Vec<(usize, (usize, OnePath))>;
type MappedPaths = HashMap<usize, (usize, Vec<Vec<usize>>)>;

pub fn run() {
    let (circuit, do_search, nthreads, task_bound) = cli::parse();
    split_search(circuit, do_search, nthreads, task_bound).expect("split_search failed")
}

#[derive(Deserialize)]
struct Jabalized {
    graph: SparseGraph,
    local_ops: Gates,
    input_map: Vec<usize>,
    output_map: Vec<usize>,
    frames_map: Vec<usize>,
    initializer: Gates,
    measurements: Measurements,
}

#[derive(Debug, Serialize)]
struct Analyzed {
    paths: Paths,
    // the next are redundent, but it's nicer to have all in one; also, I might track
    // these "final" results with git
    frames: Frames,
    frames_transposed: Vec<Vec<PauliTuple>>,
    graph: SparseGraph,
    local_ops: Gates,
    input_map: Vec<usize>,
    output_map: Vec<usize>,
    frames_map: Vec<usize>,
    initializer: Gates,
    measurements: Measurements,
}

fn read(path: impl Into<OsString>) -> Result<(Frames, Jabalized)> {
    let path: OsString = path.into();

    fn push(mut path: OsString, suffix: &str) -> OsString {
        path.push(suffix);
        path
    }

    Ok((
        serde_json::from_reader(
            File::open(push(path.clone(), "frames.json")).context("read frames")?,
        )
        .context("deserialize frames")?,
        serde_json::from_reader(
            File::open(push(path, "jabalize.json")).context("read jabalize")?,
        )
        .context("deserialize jabalize")?,
    ))
}

// the logic of the path search is basically described in paul_tracker's documentation
// in the schedule module; here I'm basically just multithreading it

fn split_search(
    mut circuit: String,
    do_search: bool,
    nthreads: u16,
    task_bound: i64,
) -> Result<()> {
    circuit.push('_');
    let output = Path::new("output");
    let file_name = output.join(circuit);
    let (frames, jabalize) = read(file_name.clone())
        .context(format!("failed to read input files for circuit {:?}", file_name))?;

    let num_bits = frames.as_storage().len();

    let frames_transposed = frames.clone().transpose_reverted(num_bits);

    let dependency_buffer = DependencyBuffer::new(num_bits);
    let graph_buffer = GraphBuffer::from_sparse(jabalize.graph.clone());
    let deps = dependency_graph::create_dependency_graph(
        Iterable::iter_pairs(frames.as_storage()),
        jabalize.frames_map.as_slice(),
    );
    // println!("deps_graph: {:?}", deps);
    // println!("num layers: {:?}", deps[0].len());

    let paths = if !do_search {
        let deps = deps.clone();
        let mut dependency_buffer = dependency_buffer.clone();
        let mut scheduler = Scheduler::<Vec<usize>>::new(
            PathGenerator::from_dependency_graph(deps, &mut dependency_buffer, None),
            Graph::new(&graph_buffer),
        );

        let mut path = Vec::new();
        let mut max_memory = 0;

        while !scheduler.time().measurable().is_empty() {
            let measurable_set = scheduler.time().measurable().clone();
            scheduler.focus_inplace(&measurable_set)?;
            path.push(measurable_set);
            max_memory = cmp::max(max_memory, scheduler.space().max_memory());
        }

        vec![(path.len(), (max_memory, path))]
    } else {
        search(
            deps,
            dependency_buffer,
            graph_buffer,
            nthreads,
            num_bits,
            task_bound,
        )?
    };

    let output = Analyzed {
        paths,
        frames,
        frames_transposed,
        graph: jabalize.graph,
        local_ops: jabalize.local_ops,
        input_map: jabalize.input_map,
        output_map: jabalize.output_map,
        frames_map: jabalize.frames_map,
        initializer: jabalize.initializer,
        measurements: jabalize.measurements,
    };

    let mut file_name =
        file_name.clone().into_os_string().into_string().map_err(|_| {
            anyhow::anyhow!("failed {file_name:?} to convert file name to string")
        })?;
    file_name.push_str("analyzed.json");
    std::fs::File::create(file_name)?
        .write_all(serde_json::to_string(&output)?.as_bytes())?;

    Ok(())
}

#[derive(Debug, Deserialize, Serialize)]
struct BitMapping {
    input: Vec<usize>,
    output: Vec<usize>,
    frames: Vec<usize>,
}

fn search(
    deps: Vec<Vec<(usize, Vec<usize>)>>,
    mut dependency_buffer: DependencyBuffer,
    graph_buffer: GraphBuffer,
    nthreads: u16,
    num_bits: usize,
    task_bound: i64,
) -> Result<Paths> {
    let scheduler = Scheduler::<Partitioner>::new(
        PathGenerator::from_dependency_graph(deps, &mut dependency_buffer, None),
        Graph::new(&graph_buffer),
    );

    let results = if nthreads < 3 {
        let (result, _) = search_single_task(scheduler, num_bits, None, None);
        result
    } else {
        threaded_search(nthreads, num_bits, scheduler, task_bound)
    }?;

    let mut filtered_results = HashMap::new();
    let mut best_memory = vec![num_bits + 1; num_bits + 1];
    for i in 0..best_memory.len() {
        if let Some((mem, _)) = results.get(&i) {
            let m = best_memory[i];
            if *mem < m {
                filtered_results.insert(i, results.get(&i).unwrap().clone());
                for m in best_memory[i..].iter_mut() {
                    *m = *mem;
                }
            }
        }
    }

    let mut sorted = filtered_results.into_iter().collect::<Vec<_>>();
    sorted.sort_by_key(|(len, _)| *len);

    // println!("sorted:");
    // for s in sorted.iter() {
    //     println!("{:?}", s);
    // }
    // println!("results:");
    // for r in results.iter() {
    //     println!("{:?}", r);
    // }

    Ok(sorted)
}

// cf. pauli_tracker::scheduler doc examples
fn search_single_task(
    scheduler: Scheduler<Partitioner>,
    num_bits: usize,
    // following two only needed for parallel search
    init_path: Option<OnePath>,
    predicates: Option<Vec<usize>>,
) -> (Result<MappedPaths>, Vec<usize>) {
    let mut results = HashMap::new();
    let mut current_path = init_path.unwrap_or_default();
    let mut best_memory =
        predicates.unwrap_or_else(|| vec![num_bits + 1; num_bits + 1]);
    let mut scheduler = scheduler.into_iter();
    while let Some(step) = scheduler.next() {
        match step {
            Step::Forward(measure) => {
                let current = scheduler.current();
                let time = current.time();
                let minimum_path_length = if time.at_leaf().is_some() {
                    current_path.len() + 1
                } else if time.has_unmeasureable() {
                    current_path.len() + 3
                } else {
                    current_path.len() + 2
                };
                if current.space().max_memory() >= best_memory[minimum_path_length] {
                    if scheduler.skip_current().is_err() {
                        break;
                    }
                } else {
                    current_path.push(measure);
                }
            }
            Step::Backward(leaf) => {
                if let Some(mem) = leaf {
                    best_memory[current_path.len()] = mem;
                    for m in best_memory[current_path.len() + 1..].iter_mut() {
                        *m = cmp::min(*m, mem);
                    }
                    results.insert(current_path.len(), (mem, current_path.clone()));
                }
                current_path.pop();
            }
        }
    }

    (Ok(results), best_memory)
}

fn threaded_search(
    nthreads: u16,
    num_bits: usize,
    mut scheduler: Scheduler<Partitioner>,
    task_bound: i64,
) -> Result<MappedPaths> {
    // there will be one thread which only collects the results and updates the shared
    // best_memory array, the other threads do the actual search tasks

    let mut pool = Pool::new(nthreads as u32);
    let (sender, receiver) = mpsc::channel::<(Vec<usize>, MappedPaths)>();

    let best_memory = Arc::new(Mutex::new(vec![num_bits + 1; num_bits + 1]));
    let results: Arc<Mutex<MappedPaths>> = Arc::new(Mutex::new(HashMap::new()));

    fn task(
        scheduler: Scheduler<Partitioner>,
        best_memory: Vec<usize>,
        _ntasks: i64,
        sender: mpsc::Sender<(Vec<usize>, MappedPaths)>,
        measure: Option<Vec<usize>>,
        num_bits: usize,
    ) -> Result<()> {
        println!("start {_ntasks:?}: measure {measure:?}; best_memory {best_memory:?}");
        let start = Instant::now();

        let (results, new_best_memory) = search_single_task(
            scheduler,
            num_bits,
            measure.map(|e| vec![e]),
            Some(best_memory),
        );

        println!(
            "done {_ntasks:?}: time {:?}; results {:?}",
            Instant::now() - start,
            results.as_ref().unwrap()
        );
        sender.send((new_best_memory, results?)).expect("send failure");
        Ok(())
    }

    let mut ntasks = 0;
    pool.scoped(|scope| {
        // update best_memory and the results
        let clone_best_memory = best_memory.clone();
        let clone_results = results.clone();
        scope.execute(move || {
            while let Ok((new_best_memory, mut new_results)) = receiver.recv() {
                let mut best_memory =
                    clone_best_memory.lock().expect("failed to lock best_memory");
                let mut results = clone_results.lock().expect("failed to lock results");

                for (i, (o, n)) in
                    best_memory.iter_mut().zip(new_best_memory).enumerate()
                {
                    if *o > n {
                        *o = n;
                        // we cannot just unwrap, because when we do the
                        // Step::Backward, we also update the best_memory for all
                        // paths with a longer path length, but we might not have
                        // collected a result for them (which is okay there)
                        if let Some(e) = new_results.remove(&i) {
                            results.insert(i, e);
                        }
                    }
                }
            }
        });

        while let Some((scheduler_focused, init_measure)) = scheduler.next_and_focus() {
            // println!("{:?}", ntasks);
            let sender = sender.clone();
            let clone_best_memory = best_memory.clone();
            // search tasks
            scope.execute(move || {
                // don't do that in the search fn call, because this would create a
                // temporary varialbe of the MutexGuard, I think, which is only
                // dropped when the function returns -> one task would block all
                // others tasks
                let best_memory = clone_best_memory
                    .lock()
                    .expect("failed to lock best_memory for task")
                    .to_vec();
                task(
                    scheduler_focused,
                    best_memory,
                    ntasks,
                    sender,
                    Some(init_measure),
                    num_bits,
                )
                .expect("task failed");
            });
            ntasks += 1;
            if ntasks == task_bound {
                break;
            }
        }

        // remaining search tasks; note that this one takes ownership of
        // sender (i.e., it is droped and we are not endlessly waiting when trying
        // to receive from the channel)
        scope.execute(move || {
            let best_memory = best_memory
                .lock()
                .expect("failed to lock best_memory for final task")
                .to_vec();
            task(scheduler, best_memory, -1, sender, None, num_bits)
                .expect("final task failed");
        });
        // drop(sender);
    });

    Ok(Arc::into_inner(results)
        .expect("failed to move out of Arc results")
        .into_inner()
        .expect("failed to move out of Mutex results"))
}
