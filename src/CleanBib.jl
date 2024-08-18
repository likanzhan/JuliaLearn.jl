function cleanbib!(orgfile)
    orgbib = read(orgfile, String)
    newbib = replace(orgbib,  Regex("url = \\{[^\\}]*?\\},")  => "url = {},")
    newbib = replace(newbib,  Regex("note = \\{[^\\}]*?\\},") => "note = {},")
    write(orgfile, newbib)
end