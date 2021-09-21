using Pkg
# Installing stim support
Pkg.add(PackageSpec(name="Conda", rev="master"))

using Conda
Conda.pip_interop(true)
Conda.pip("install", "stim>=1.2.1")
