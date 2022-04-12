using Pkg
# Installing stim support
Pkg.add(PackageSpec(name="Conda", rev="master"))

using Conda
Conda.pip_interop(true)
Conda.pip("install", "stim>=1.2.1")
Conda.pip("install", "cirq")

# Force PyCall to use Julia specific python distribution
ENV["PYTHON"] = ""
Pkg.build("PyCall")
