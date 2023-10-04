use clap::{
    value_parser,
    Arg,
    ArgAction,
    Command,
};

const CIRCUIT: &str = "circuit";
const NTHREADS: &str = "nthreads";
const TASK_BOUND: &str = "task_bound";
const SEARCH: &str = "search";

fn build() -> Command {
    Command::new(env!("CARGO_PKG_NAME"))
        .version(env!("CARGO_PKG_VERSION"))
        .author(env!("CARGO_PKG_AUTHORS"))
        .about(env!("CARGO_PKG_DESCRIPTION"))
        .arg_required_else_help(true)
        .arg(
            Arg::new(SEARCH)
                .short('s')
                .long("search")
                .help("Search for all best paths")
                .long_help("Search for all best paths. This may take some time ...")
                .action(ArgAction::SetTrue)
        )
        .arg(
            Arg::new(CIRCUIT)
                .value_name("CIRCUIT")
                .help("The circuit's file name (prefix)")
                .required(true),
        )
        .arg(
            Arg::new(NTHREADS)
                .value_name("NTHREADS")
                .short('n')
                .long("nthreads")
                .help("The number of threads to use for the search")
                .long_help(
r"The number of threads to use for the search. If NTHREADS is below 3, it will not
multithread. Otherwise it will start a threadpool, where one thread is used to manage
shared data. The tasks for the threadpool are all the possible focused Scheduler sweeps
after doing one initial focus, cf. source code .... The number of those task scales
exponentially with the number of bits in the first layer of the dependency graph. Use
the -b/--task-bound option to limit the number of these tasks (but the last task may
    take some time because it does all remaining tasks)."
                )
                .default_value("1")
                .value_parser(value_parser!(u16)),
        )
        .arg(
            Arg::new(TASK_BOUND)
                .value_name("TASK_BOUND")
                .short('b')
                .long("task-bound")
                .help("A bound on the possible number of tasks")
                .long_help(
r"A bound on the possible number of tasks. Compare the long help message for the
-n/--nthreads option."
                )
                .default_value("10000")
                .value_parser(value_parser!(u32))
        )
}

pub fn parse() -> (String, bool, u16, i64) {
    let mut args = build().get_matches();
    (
        args.remove_one(CIRCUIT).expect("is boolean flag"),
        args.remove_one(SEARCH).expect("is required"),
        args.remove_one(NTHREADS).expect("has default"),
        args.remove_one::<u32>(TASK_BOUND).expect("has default").into(),
    )
}
