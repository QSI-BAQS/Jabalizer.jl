# todo: crossplatform and something like an absolute path
lib = "./pauli_tracker_extern/c_api/output/libpauli_tracker_clib.so"

struct Frames end

function frames_new()::Ptr{Frames}
    @ccall lib.frames_hmpsvbfx_new()::Ptr{Frames}
end

function frames_free(frames::Ptr{Frames})::Cvoid
    @ccall lib.frames_hmpsvbfx_free(frames::Ptr{Frames})::Cvoid
end

function frames_serialize(frames::Ptr{Frames}, file::String)::Cvoid
    @ccall lib.frames_hmpsvbfx_serialize(frames::Ptr{Frames}, Base.cconvert(Cstring,
    file)::Cstring)::Cvoid
end

function frames_init(num_qubits::UInt)::Ptr{Frames}
    @ccall lib.frames_hmpsvbfx_init(num_qubits::UInt)::Ptr{Frames}
end

function frames_track_x(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_track_x(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_track_y(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_track_y(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_track_z(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_track_z(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_h(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_h(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_s(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_s(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_cz(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_cz(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
end

function frames_x(_::Ptr{Frames}, _::UInt)::Cvoid end
function frames_y(_::Ptr{Frames}, _::UInt)::Cvoid end
function frames_z(_::Ptr{Frames}, _::UInt)::Cvoid end

function frames_sdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_sdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_sx(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_sx(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_sxdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_sxdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_sy(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_sy(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_sydg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_sydg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_sz(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_sz(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_szdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_szdg(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end

function frames_cx(frames::Ptr{Frames}, control::UInt, target::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_cx(frames::Ptr{Frames}, control::UInt, target::UInt)::Cvoid
end

function frames_swap(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_swap(frames::Ptr{Frames}, qubit_a::UInt, qubit_b::UInt)::Cvoid
end

function frames_new_qubit(frames::Ptr{Frames}, qubit::UInt)::Cvoid
    @ccall lib.frames_hmpsvbfx_new_qubit(frames::Ptr{Frames}, qubit::UInt)::Cvoid
end
