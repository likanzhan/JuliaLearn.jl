using Weave, Mustache
import FileWatching: watch_file
using Markdown
import Markdown: latex, Table, wrapblock, latexinline

## change latex cmd, ``-8bit'': correctly show tab
# const MY_LATEX_CMD = ["xelatex", "-8bit", "-shell-escape", "-synctex=1", "-interaction=nonstopmode", "-file-line-error"]
const MY_LATEX_CMD = [
    "latexmk",
    "-pdfxe",
    "-xelatex",
    "-8bit",
    "-shell-escape",
    "-synctex=1",
    "-interaction=nonstopmode",
    "-file-line-error",
]

## change chunk defaults to defaults defined in type `LaTeXMinted()`; xleftmargin=0.5em, fontsize=\\small, 
function __init__()
    WeaveChunkDefault = Weave.get_chunk_defaults()
    MintedDefault = Weave.LaTeXMinted()
    MintedDefaultDict = Dict(
        property => getproperty(MintedDefault, property) for
        property ∈ propertynames(MintedDefault)
    )
    for existKey in keys(WeaveChunkDefault)
        if existKey in keys(MintedDefaultDict)
            Weave.set_chunk_defaults!(existKey => MintedDefaultDict[existKey])
        end
    end
    Weave.register_format!(
        "minted2pdf",
        Weave.LaTeX2PDF(
            primaryformat = Weave.LaTeXMinted(
                codestart = "\\begin{compactminted}[texcomments = false, mathescape = true, bgcolor = GhostWhite, frame = none]{julia}",
                codeend = "\\end{compactminted}",
                outputstart = "\\begin{compactminted}[texcomments = false, mathescape = true, bgcolor = GhostWhite, frame = leftline]{julia}",
                outputend = "\\end{compactminted}",
            ),
        ),
    )
end

## Define methods for `LaTeXMinted`
Weave.unicode2latex(docformat::Weave.LaTeXMinted, s, escape = false) = s
Weave.render_chunk(docformat::Weave.LaTeXMinted, chunk::Weave.DocChunk) =
    join((Weave.render_inline(c) for c in chunk.content))
Weave.render_doc(docformat::Weave.LaTeXMinted, body, doc) =
    Mustache.render(mt"{{{ :body }}}"; body = body)

"""
    jnw3pdf(filepath)

Convert a jnw file into a pdf file when `filepath` is changed
"""
function jnw3pdf(filepath)
    filepath, filename, filesremove = findRelevantFiles(filepath)
    while true
        event = watch_file(filepath)
        if event.changed
            try
                jnw2pdf(filepath)
            catch err
                @warn("Error happens:\n$err")
            end
        end
    end
end

"""
    jnw2pdf(filepath)

Convert a jnw file into a pdf file
"""
function jnw2pdf(filepath; doctype = "minted2pdf")
    filepath, filename, filesremove = findRelevantFiles(filepath)
    weave(
        filepath,
        cache = :off,
        fig_path = string(filename, "_Figures"),
        doctype = doctype, # minted2pdf ; texminted
        latex_cmd = MY_LATEX_CMD,
    )

    try
        rm.(filesremove)
    catch
        "Cannot remove Files"
    end

end

function findRelevantFiles(filepath)
    dir, file = splitdir(filepath)
    filename, fileExtension = split(file, ".")
    fileExtension == "jnw" || error("Extension should be $(fileExtension)")
    # RemveExtensions  = ["aux", "bcf", "log", "out", "run.xml", "toc", "synctex.gz"]
    RemveExtensions = [
        "aux",
        "xdv",
        "toc",
        "synctex.gz",
        "out",
        "log",
        "fls",
        "fdb_latexmk",
        "blg",
        "bbl",
        "pyg",
    ]
    filesremove = joinpath.(dir, string.(filename, ".", RemveExtensions))
    return filepath, filename, filesremove
end

#################################
### Add table environment to table.
function latex(io::IO, md::Table) # Markdown.jl/src/GitHub/table.jl
    println(io, "\\begin{table}[htpb]")
    write(io, "\\small\n")
    println(io, "\\centering")
    wrapblock(io, "tabular") do
        align = md.align
        println(io, "{$(join(align))}")
        println(io, "\\toprule")
        for (i, row) in enumerate(md.rows)
            for (j, cell) in enumerate(row)
                j != 1 && print(io, " & ")
                latexinline(io, cell)
            end
            println(io, " \\\\")
            if i == 1
                println(io, "\\midrule")
            end
        end
        println(io, "\\bottomrule")
    end
    println(io, "\\end{table}")
end


import Printf: @sprintf
import DataFrames:
    _show,
    AbstractDataFrame,
    _check_consistency,
    _names,
    latex_escape,
    batch_compacttype,
    SHOW_TABULAR_TYPES,
    ourshow

"""
    ProtectUnicode(x::AbstractChar)

Protect Unicode with "\$". 
"""
function ProtectUnicode(x::AbstractChar)
    if x in ['\\','~', '#', '$', '%', '&', '_', '^', '{', '}'] # escaped
        return x
    elseif codepoint(x) < 0xa1 # https://docs.julialang.org/en/v1/manual/unicode-input/
        return x
    else
        return "\$$x\$"
    end
end
ProtectUnicode(x::AbstractString) = string(map(x -> ProtectUnicode(x), collect(x))...)

"""
    _show()

redefine `_show()` methods defined by `DataFrames`.

"""
Base.show(io::IO, mime::MIME"text/latex", df::AbstractDataFrame; eltypes::Bool=false) =
    _show(io, mime, df, eltypes=eltypes)
function _show(
    io::IO,
    ::MIME"text/latex",
    df::AbstractDataFrame;
    eltypes::Bool = true,
    rowid = nothing,
)
    _check_consistency(df)

    # we will pass around this buffer to avoid its reallocation in ourstrwidth
    buffer = IOBuffer(Vector{UInt8}(undef, 80), read = true, write = true)

    if rowid !== nothing
        if size(df, 2) == 0
            rowid = nothing
        elseif size(df, 1) != 1
            throw(ArgumentError("rowid may be passed only with a single row data frame"))
        end
    end

    mxrow, mxcol = size(df)
    if get(io, :limit, false)
        tty_rows, tty_cols = get(io, :displaysize, displaysize(io))
        mxrow = min(mxrow, tty_rows)
        maxwidths = getmaxwidths(df, io, 1:mxrow, 0:-1, :X, nothing, true, buffer, 0) .+ 2
        mxcol = min(mxcol, searchsortedfirst(cumsum(maxwidths), tty_cols))
    end

    cnames = _names(df)[1:mxcol]
    alignment = repeat("c", mxcol)
    write(io, "\\begin{table}[htpb]\n")
    write(io, "\\small\n")
    write(io, "\\centering\n")
    write(io, "\\begin{tabular}{r|")
    write(io, alignment)
    mxcol < size(df, 2) && write(io, "c")
    write(io, "}\n")
    write(io, "\\toprule\n")
    write(io, "\t& ")
    # header = join(map(c -> latex_escape(string(c)), cnames), " & ")
    header = join(map(c -> ProtectUnicode(latex_escape(string(c))), cnames), " & ") # Likan
    write(io, header)
    mxcol < size(df, 2) && write(io, " & ")
    write(io, "\\\\\n")
    if eltypes
        write(io, "\t& ")
        ct = batch_compacttype(Any[eltype(df[!, idx]) for idx = 1:mxcol], 9)
        header = join(latex_escape.(ct), " & ")
        write(io, header)
        mxcol < size(df, 2) && write(io, " & ")
        write(io, "\\\\\n")
    end
    write(io, "\t\\midrule\n")
    for row = 1:mxrow
        write(io, "\t")
        write(io, @sprintf("%d", rowid === nothing ? row : rowid))
        for col = 1:mxcol
            write(io, " & ")
            if !isassigned(df[!, col], row)
                print(io, "\\emph{\\#undef}")
            else
                cell = df[row, col]
                if ismissing(cell)
                    print(io, "\\emph{missing}")
                elseif cell isa Markdown.MD
                    print(io, strip(repr(MIME("text/latex"), cell)))
                elseif cell isa SHOW_TABULAR_TYPES
                    print(io, "\\emph{")
                    print(io, latex_escape(sprint(ourshow, cell, 0, context = io)))
                    print(io, "}")
                else
                    if showable(MIME("text/latex"), cell)
                        show(io, MIME("text/latex"), cell)
                    else
                        print(io, latex_escape(sprint(ourshow, cell, 0, context = io)))
                    end
                end
            end
        end
        mxcol < size(df, 2) && write(io, " & \$\\dots\$")
        write(io, " \\\\\n")
    end
    if size(df, 1) > mxrow
        write(io, "\t\$\\dots\$")
        for col = 1:mxcol
            write(io, " & \$\\dots\$")
        end
        mxcol < size(df, 2) && write(io, " & ")
        write(io, " \\\\\n")
    end
    write(io, "\\bottomrule\n")
    write(io, "\\end{tabular}\n")
    write(io, "\\end{table}\n")
end
