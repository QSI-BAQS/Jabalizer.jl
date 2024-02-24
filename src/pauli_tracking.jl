module pauli_tracking

function apply_gate(
    frames, # Frames object
    gate::Tuple{String,Vector{UInt}},
)
    name = gate[1]
    bits = gate[2]
    if name == "H"
        frames.h(bits[1])
    elseif name == "S"
        frames.s(bits[1])
    elseif name == "CZ"
        frames.cz(bits[1], bits[2])
    elseif name == "X" || name == "Y" || name == "Z"
    elseif name == "S_DAG"
        frames.sdg(bits[1])
    elseif name == "SQRT_X"
        frames.sx(bits[1])
    elseif name == "SQRT_X_DAG"
        frames.sxdg(bits[1])
    elseif name == "SQRT_Y"
        frames.sy(bits[1])
    elseif name == "SQRT_Y_DAG"
        frames.sydg(bits[1])
    elseif name == "SQRT_Z"
        frames.sz(bits[1])
    elseif name == "SQRT_Z_DAG"
        frames.szdg(bits[1])
    elseif name == "CNOT"
        frames.cx(bits[1], bits[2])
    elseif name == "SWAP"
        frames.swap(bits[1], bits[2])
    else
        error("Unknown gate: $name")
    end
end


end