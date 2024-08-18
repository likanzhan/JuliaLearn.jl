using PDFIO, CSV, DataFrames

"""
    PageCount(Path2File)

1. Export Endnote library with the format 'MyOwnStyle'.
2. No more than one pdf should be included in each item.
3. Run the function to calculate the page count.

# Example
```jldoctest
PageCount("NewArticles.txt")
```
"""
function PageCount(Path2File)
    LibraryPath, LibraryFile = dirname(Path2File), basename(Path2File)
    LibraryName = split(LibraryFile, ".")[1]
    LibraryDir = "/Users/likanzhan/Documents/Meta/Read/EndNote"
    function _CountThePage(File)
        file_dir = joinpath(LibraryDir, "$LibraryName.enlp/$LibraryName.Data/PDF", File)
        try
            return pdDocGetPageCount(pdDocOpen(file_dir))
        catch e
            return missing
        end
    end
    dt = CSV.read(joinpath(LibraryPath, "$LibraryName.txt"), DataFrame;
        delim="   ", header=false)
    transform!(dt, :Column1 => ByRow(x -> split(x, "\t")) => [:Year, :Author, :Title, :Source, :Type, :File])
    transform!(dt, :File => ByRow(x -> replace(x, "internal-pdf://" => "")) => :File)
    transform!(dt, :File => ByRow(_CountThePage) => :PageCount)
    select!(dt, [:Year, :Author, :Title, :Source, :Type, :PageCount])
    CSV.write(joinpath(LibraryPath, "$LibraryName.csv"), dt; bom=true)
    return dt[ismissing.(dt.PageCount), :]
end

