"""
    PrintSourceCode(PackageName::T; RootDir::T = pwd()) where T<:AbstractString

Convert `PackageName.jl` file in `src` and all `include()`ed files of package `PackageName` to a tex file: `PackageName.tex`
and store it in `RootDir`.

# Example
```jldoctest
PrintSourceCode("LinearAlgebra")
```
"""
function PrintSourceCode(
    PackageName::T;
    RootDir::T = pwd()
) where {T<:AbstractString}

    ## 1. Retrieve package directory
    if PackageName == "Base"
        PackagePath = normpath(joinpath(Base.Sys.BINDIR, "..", "share/julia/base/"))
    else
        PackagePath = dirname(Base.find_package(PackageName))
    end

    ## 2. Retrieve file name and file version
    if occursin("base", PackagePath)
        FileName = "Base"
        FileVersion = string(VERSION)
    elseif occursin("stdlib", PackagePath)
        FileName    = basename(dirname(PackagePath))
        FileVersion = basename(dirname(dirname(PackagePath)))
    else
        FileName    = basename(dirname(dirname(PackagePath)))
        FileVersion = basename(dirname(PackagePath))
    end

    ## 4. Retrieve Filelist from file "PackageName.jl"
    FileList = String[PackageName * ".jl"]
    for ln in readlines(joinpath(PackagePath, PackageName * ".jl"))
        if occursin(r"include\(\"(.*?)\"\)$", ln)
            file = replace(ln, r"include\(\"(.*?)\"\)$" => s"\1")
            push!(FileList, file)
        end
    end

    ## 5. Write the file list to a tex file
    pre = """
    \\documentclass[11pt]{article}
    \\usepackage{/Users/likanzhan/Documents/Meta/Technique/LaTex/Preamble_Article}
    \\begin{document}
    \\tableofcontents
    \\newpage
    """
    post = "\\end{document}"
    TexFile = joinpath(RootDir, FileName * ".tex")

    open(TexFile, "w") do io
        println(io, pre)
        for file in FileList
            fileRep = replace(file, "_" => "\\_")
            println(io, "\\section{", joinpath(fileRep), "}")
            println(io, "\\inputminted{julia}{", joinpath(PackagePath, file), "}")
            println(io, "\\newpage", "\n")
        end
        println(io, "\n", post)
        println(io, "%%%%%% PkgV: " * FileVersion)
    end

    @info """

    - Source Directory: `$PackagePath`
    - Tex File: `$TexFile`
    - FileName: `$FileName`; 
    - FileVersion: `$FileVersion`

    """
end