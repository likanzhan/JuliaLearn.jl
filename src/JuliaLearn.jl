module JuliaLearn

# Calculate Hypothesis Matrix
export HypothesisMatrix
include("HypothesisMatrix.jl")

# PrintSourceCode
export PrintSourceCode
include("Print_Source_Code.jl")

# CombineScreenShots
export CombineScreenShots
include("Combine_Screen_Shots.jl")

# Text_to_Speech
export synthesize_audio
include("Text_to_Speech.jl")

# jnw
export jnw2pdf, jnw2qmd
include("Jnw2pdf.jl")
include("Jnw2qmd.jl")

# Simulate data and check hypothesis being tested
export SimulateData, Hypothesis
include("Simulate_Data.jl")

# CheckOrthogonality
export CheckOrthogonality
include("Check_Orthogonality.jl")

# Update LaTeX Workshop for VSCode
export Update_James, Latex_Snippets
include("LaTeX_Workshop.jl")

# Clean biblography file for latex
export cleanbib!
include("CleanBib.jl")

# Clean biblography file for latex
export PageCount
include("PageCount.jl")


end # module
