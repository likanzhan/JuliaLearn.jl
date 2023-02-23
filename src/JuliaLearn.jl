module JuliaLearn

# PrintSourceCode
export PrintSourceCode
include("Print_Source_Code.jl")

# CombineScreenShots
export CombineScreenShots
include("Combine_Screen_Shots.jl")

# PlotTopography
export PlotTopography
include("Plot_Topography.jl")

# jnw2pdf
export jnw2pdf, jnw3pdf
include("Jnw2pdf.jl")

# Simulate data and check hypothesis being tested
export SimulateData, Hypothesis
include("Simulate_Data.jl")

# CheckOrthogonality
export CheckOrthogonality
include("Check_Orthogonality.jl")

# Update LaTeX Workshop for VSCode
export Update_James, Latex_Snippets
include("LaTeX_Workshop.jl")

end # module
