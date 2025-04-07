using JSON3, JSON, DataStructures

### 1. Define constants
### 1.1. Define jnw2pdf recipe and add `-shell-escape` to xelatex engine
const jnw2pdf_recipe = ["jnw2pdf"]
const rnw2pdf_recipe = ["rnw2tex", "xelatexmk"]

const jnw2pdf_tool = OrderedDict{String,Any}(
    "name" => "jnw2pdf",
    "command" => "julia",
    "args" => ["-e", "using JuliaLearn; jnw2pdf(\"%DOC_EXT%\")"],
    "env" => OrderedDict{String,Any}(),
)

const xelatex_args = [
    "-synctex=1",
    "-interaction=nonstopmode",
    "-file-line-error",
    "-xelatex",
    "-shell-escape",
    "-outdir=%OUTDIR%",
    "%DOC%",
]

### 1.2. Define two snippets: JuliaWeaveChunk, and JuliaWevaInline
const juliaweavechunk =
    "juliaweavechunk" => OrderedDict{String,Any}(
        "prefix" => "JWC",
        "body" => "<<results=\"hidden\", echo=false>>=\n\${0:\${TM_SELECTED_TEXT}}\n@",
        "description" => "julia weave chunk",
    )

const juliaweaveinline =
    "juliaweaveinline" => OrderedDict{String,Any}(
        "prefix" => "JWI",
        "body" => "\\mintinline[breaklines=true]{julia}{\${0:\${TM_SELECTED_TEXT}}}",
        "description" => "julia weave inline",
    )

const frameItemize = 
    "frameItemize" => OrderedDict{String,Any}(
        "prefix" => "FRIT",
        "body" => "\\begin{frame}\n\t\\frametitle{\${1:<title>}}\n\n\t\\begin{itemize}[<+(1)->]\n\t\\item \${0:\${TM_SELECTED_TEXT}}\n\t\\end{itemize}\n\n\\end{frame}",
        "description" => "frame + itemize",
    )

const PreambleArticle =
    "PreambleArticle" => OrderedDict{String,Any}(
        "prefix" => "PRAR",
        "body" => "\\usepackage{/Users/likanzhan/Documents/Meta/Technique/LateX/Preamble_Article}",
        "description" => "Preamble To Article",
    )

const PreambleBeamer =
    "PreambleBeamer" => OrderedDict{String,Any}(
        "prefix" => "PRBM",
        "body" => "\\usepackage{/Users/likanzhan/Documents/Meta/Technique/LateX/Preamble_Beamer}",
        "description" => "Preamble to Beamer",
    )

### 3. Retrieve the current james
function Get_Current_James()
    extention_dir = joinpath(homedir(), ".vscode", "extensions")
    extensions = filter(isdir, readdir(extention_dir, join = true))
    james_yu_all =
        extensions[findall(x -> occursin("james-yu.latex-workshop-", x), extensions)]
    isempty(james_yu_all) && error("James-Yu extension not installed")

    current_james = maximum(james_yu_all)

    return current_james
end

### 4. Function to update LaTeX engine
function Update_Latex_Engine!(current_james)
    original_specification = joinpath(current_james, "package_original.json")
    current_specification  = joinpath(current_james, "package.json")
    isfile(original_specification) || mv(current_specification, original_specification)

    open(current_specification, "w") do current_data
        Latex_Dict =
            JSON.parsefile(original_specification; dicttype = DataStructures.OrderedDict)
        latex_recipes =
            Latex_Dict["contributes"]["configuration"]["properties"]["latex-workshop.latex.recipes"]["default"]
        latex_recipes_new = latex_recipes[[4, 7, 6, 1:3..., 5, 6, 8:end...]]  # Correct order to use xelatex        

        empty!(latex_recipes)
        append!(latex_recipes, latex_recipes_new)
        
        latex_tools =
            Latex_Dict["contributes"]["configuration"]["properties"]["latex-workshop.latex.tools"]["default"]

        for recipe in latex_recipes
            recipe["name"] == "Compile Jnw files" &&
                setindex!(recipe, jnw2pdf_recipe, "tools")
            recipe["name"] == "Compile Rnw files" &&
                setindex!(recipe, rnw2pdf_recipe, "tools")
        end

        "jnw2pdf" in [dict["name"] for dict in latex_tools] || push!(latex_tools, jnw2pdf_tool)

        for tool in latex_tools
            if tool["name"] == "xelatexmk"
                "-shell_escape" in tool["args"] || setindex!(tool, xelatex_args, "args")
            end
        end

        JSON3.pretty(current_data, JSON3.write(Latex_Dict))
    end

end

### 5. Function to update LaTeX snippets
function Update_Latex_Snippets!(current_james)
    original_latex_snippet = joinpath(current_james, "data", "latex-snippet_original.json")
    current_latex_snippet = joinpath(current_james,  "data", "latex-snippet.json")
    isfile(original_latex_snippet) || mv(current_latex_snippet, original_latex_snippet)

    open(current_latex_snippet, "w") do current_data
        Snippet_Dict =
            JSON.parsefile(original_latex_snippet; dicttype = DataStructures.OrderedDict)

        categories = [first(x) for x in Snippet_Dict]
        "juliaweavechunk"  in categories || push!(Snippet_Dict, juliaweavechunk)
        "juliaweaveinline" in categories || push!(Snippet_Dict, juliaweaveinline)
        "frameItemize"     in categories || push!(Snippet_Dict, frameItemize)
        "PreambleArticle"  in categories || push!(Snippet_Dict, PreambleArticle)
        "PreambleBeamer"   in categories || push!(Snippet_Dict, PreambleBeamer)

        JSON3.pretty(current_data, JSON3.write(Snippet_Dict))
    end

end

### 5. Retrieve Latex Snippets
function Latex_Snippets()
    current_james = Get_Current_James()
    current_latex_snippet = joinpath(current_james, "data", "latex-snippet.json")
    Snippet_Dict =
        JSON.parsefile(current_latex_snippet; dicttype = DataStructures.OrderedDict)

    All_Snippets = OrderedDict{String,String}()

    for dict in Snippet_Dict
        name = first(dict)
        current_snnipet = Snippet_Dict[name]
        if "prefix" in keys(current_snnipet)
            prfx = current_snnipet["prefix"]
            push!(All_Snippets, prfx => name)
        end
    end

    return All_Snippets

end

### 6. Get the extension directory of the latex James-Yu Latex under vscode.
function Update_James()
    current_james = Get_Current_James()
    Update_Latex_Engine!(current_james)
    Update_Latex_Snippets!(current_james)
end
