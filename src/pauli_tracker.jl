module pauli_tracker

lib = normpath(joinpath(dirname(@__FILE__), "..",
    "pauli_tracker/c_lib/dist/libpauli_tracker_clib"))
if Sys.iswindows()
    lib = lib * ".dll"
elseif Sys.isapple()
    lib = lib * ".dylib"
else
    lib = lib * ".so"
end

struct Frames end
struct Storage end

function frames_new()::Ptr{Frames}
    @ccall lib.frames_hmpsbvfx_new()::Ptr{Frames}
end

function frames_free(frames::Ptr{Frames})::Cvoid
    @ccall lib.frames_hmpsbvfx_free(frames::Ptr{Frames})::Cvoid
end

function frames_serialize(frames::Ptr{Frames}, file::String)::Cvoid
    @ccall lib.frames_hmpsbvfx_serialize(
        frames::Ptr{Frames}, Base.cconvert(Cstring, file)::Cstring
    )::Cvoid
end

function frames_deserialize(file::String)::Ptr{Frames}
    @ccall lib.frames_hmpsbvfx_deserialize(
        Base.cconvert(Cstring, file)::Cstring
    )::Ptr{Frames}
end

function frames_serialize_bin(frames::Ptr{Frames}, file::String)::Cvoid
    @ccall lib.frames_hmpsbvfx_serialize_bin(
        frames::Ptr{Frames}, Base.cconvert(Cstring, file)::Cstring
    )::Cvoid
end

function frames_deserialize_bin(file::String)::Ptr{Frames}
    @ccall lib.frames_hmpsbvfx_deserialize_bin(
        Base.cconvert(Cstring, file)::Cstring
    )::Ptr{Frames}
end

function show_frames(frames::Ptr{Frames})::Cvoid
    @ccall lib.show_frames(frames::Ptr{Frames})::Cvoid
end

function frames_init(num_qubits::UInt)::Ptr{Frames}
    @ccall lib.frames_hmpsbvfx_init(num_qubits::UInt)::Ptr{Frames}
end

function frames_track_x(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_track_x(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_track_y(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_track_y(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_track_z(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_track_z(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_id(_::Ptr{Frames}, _::UInt)::Cvoid end
function frames_x(_::Ptr{Frames}, _::UInt)::Cvoid end
function frames_y(_::Ptr{Frames}, _::UInt)::Cvoid end
function frames_z(_::Ptr{Frames}, _::UInt)::Cvoid end
function frames_s(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_s(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_sdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_sdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_sz(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_sz(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_szdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_szdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_hxy(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_hxy(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_h(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_h(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_sy(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_sy(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_sydg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_sydg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_sh(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_sh(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_hs(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_hs(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_shs(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_shs(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_sx(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_sx(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_sxdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_sxdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
function frames_hyz(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_hyz(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_cz(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_cz(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
end
function frames_cx(frames::Ptr{Frames}, control::UInt, target::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_cx(frames::Ptr{Frames}, control::UInt, target::UInt)::Cvoid
end
function frames_cy(frames::Ptr{Frames}, control::UInt, target::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_cy(frames::Ptr{Frames}, control::UInt, target::UInt)::Cvoid
end
function frames_swap(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_swap(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
end
function frames_iswap(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_iswap(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
end
function frames_iswapdg(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_iswapdg(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
end

function frames_move_x_to_x(frames::Ptr{Frames}, origin::UInt, new::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_move_x_to_x(frames::Ptr{Frames}, origin::UInt, new::UInt)::Cvoid
end
function frames_move_x_to_z(frames::Ptr{Frames}, origin::UInt, new::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_move_x_to_z(frames::Ptr{Frames}, origin::UInt, new::UInt)::Cvoid
end
function frames_move_z_to_x(frames::Ptr{Frames}, origin::UInt, new::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_move_z_to_x(frames::Ptr{Frames}, origin::UInt, new::UInt)::Cvoid
end
function frames_move_z_to_z(frames::Ptr{Frames}, origin::UInt, new::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_move_z_to_z(frames::Ptr{Frames}, origin::UInt, new::UInt)::Cvoid
end

function frames_new_qubit(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsbvfx_new_qubit(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function storage_new()::Ptr{Storage}
    @ccall lib.map_psvbfx_new()::Ptr{Storage}
end

function storage_free(storage::Ptr{Storage})::Cvoid
    @ccall lib.map_psvbfx_free(storage::Ptr{Storage})::Cvoid
end

function storage_serialize(storage::Ptr{Storage}, file::String)::Cvoid
    @ccall lib.map_psvbfx_serialize(storage::Ptr{Storage}, Base.cconvert(Cstring,
        file)::Cstring)::Cvoid
end

function frames_measure_and_store(frames::Ptr{Frames}, bit::UInt, storage::Ptr{Storage})::Cvoid
    @ccall lib.frames_hmpsbvfx_measure_and_store(frames::Ptr{Frames}, bit::UInt, storage::Ptr{Storage})::Cvoid
end

function frames_measure_and_store_all(frames::Ptr{Frames}, storage::Ptr{Storage})::Cvoid
    @ccall lib.frames_hmpsbvfx_measure_and_store_all(frames::Ptr{Frames}, storage::Ptr{Storage})::Cvoid
end

end
