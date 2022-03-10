module JuliaLearn

# plot_topography
using Makie
import Statistics: mean
import GMT: triangulate

export plot_topography

include("plot_topography.jl")

end # module
