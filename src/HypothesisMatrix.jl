using DataFrames
using StatsModels

function HypothesisMatrix(
        contrasts = DummyCoding();
        r = 2,
        c = 3,
        Interaction = true
    )
    rlevel = 'R' .* collect('1':Char('0' + r))
    clevel = 'C' .* collect('1':Char('0' + c))

    RC = [x * y for x in rlevel for y in clevel]

    R = StatsModels.ContrastsMatrix(contrasts, rlevel)
    C = StatsModels.ContrastsMatrix(contrasts, clevel)
    # propertynames(R)

    dfr = DataFrame(R.matrix, R.coefnames)
    dfc = DataFrame(C.matrix, C.coefnames)
    dfcr = crossjoin(dfr, dfc)

    RN = filter(x -> occursin(r"R", x), names(dfcr))
    CN = filter(x -> occursin(r"C", x), names(dfcr))
    coefnms = ["Intercept"; RN; CN]

    Interaction &&
    for rn in RN, cn in CN
        push!(coefnms, rn * ":" * cn)
        transform!(dfcr, [rn, cn] => ByRow(*) => rn*cn)
    end

    hpm = StatsModels.hypothesis_matrix(Matrix(dfcr), intercept = true)
    dfhp = DataFrame(hpm, RC)
    insertcols!(dfhp, 1, :Coef => coefnms)

    return dfhp
end