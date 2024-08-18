"""
    PrintSourceCode(PackageName::T; RootDir::T = pwd()) where T<:AbstractString

Convert `PackageName.jl` file in `src` and all `include()`ed files of package `PackageName` to a tex file: `PackageName.tex`
and store it in `RootDir`.

# Example
```jldoctest
PrintSourceCode("LinearAlgebra")
```
"""
function PrintSourceCode(PackageName::T; RootDir::T = pwd()) where {T<:AbstractString}

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
        FileName = basename(dirname(PackagePath))
        FileVersion = basename(dirname(dirname(PackagePath)))
    else
        FileName = basename(dirname(dirname(PackagePath)))
        FileVersion = basename(dirname(PackagePath))
    end

    ## 4. Retrieve Filelist from file "PackageName.jl"

    function CaptureInclude(PackageName)
        if PackageName == "Base"
            PackagePath = normpath(joinpath(Base.Sys.BINDIR, "..", "share/julia/base/"))
        else
            PackagePath = dirname(Base.find_package(PackageName))
        end

        PackageFile = PackageName * ".jl"

        dst = String[]
        push!(dst, joinpath(PackagePath, PackageFile))

        for lv1 in readlines(joinpath(PackagePath, PackageFile))
            flv1 = match(r"include\(\s*?\"(.*?)\"\)$", lv1)
            if !isnothing(flv1)
                cpt1 = (flv1.captures)[]
                push!(dst, joinpath(PackagePath, cpt1))
                if occursin.("/", cpt1)
                    folder = splitdir(cpt1)[1]
                    for lv2 in readlines(joinpath(PackagePath, cpt1))
                        flv2 = match(r"include\(\s*?\"(.*?)\"\)$", lv2)
                        isnothing(flv2) ||
                            push!(dst, joinpath(PackagePath, folder, (flv2.captures)[]))
                    end
                end
            end
        end

        return dst
    end

    FileList = CaptureInclude(PackageName)


    # FileList = String[]
    # for (root, dirs, files) in walkdir(PackagePath)
    #     push!.(Ref(FileList), joinpath.(root, filter!(endswith(".jl"), files)) )
    # end

    ## 5. Write the file list to a tex file
    pre = """
    \\documentclass[10pt]{article}
    \\usepackage{/Users/likanzhan/Documents/Meta/Technique/LaTex/Preamble_Article}
    \\usepackage{minted}
    \\begin{document}
    \\tableofcontents
    \\newpage
    """
    post = "\\end{document}"
    TexFile = joinpath(RootDir, FileName * ".tex")

    open(TexFile, "w") do io
        println(io, pre)
        for file in FileList
            fileRep = replace(file, PackagePath => "")
            fileRep = replace(fileRep, r"^/" => "")
            fileRep = replace(fileRep, "_" => "\\_")
            println(io, "\\section{", joinpath(fileRep), "}")
            println(
                io,
                "\\inputminted[fontsize=\\scriptsize]{julia}{",
                joinpath(PackagePath, file),
                "}",
            )
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
