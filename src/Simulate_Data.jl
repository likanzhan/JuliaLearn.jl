using LinearAlgebra
using Distributions
using DataFrames
using StatsModels
using GLM

function SimulateData(;
    B = 3,
    W = [2, 2],
    M = [
        40 50 60 70
        30 40 50 60
        20 30 40 50
    ],
    SD = 2,
    n = 1,
    R = 0,
)
    nBcomb = ismissing(B) ? 1 : prod(B)
    nWcomb = ismissing(W) ? 1 : prod(W)

    # Between participant factor label
    if !ismissing(B)
        BetweenFactorName = string.(collect('A':'Z')[1:length(B)])
        BetweenFactorLevel = [string.(BetweenFactorName[i], 1:B[i]) for i = 1:length(B)]
        BetweenFactorLabel = repeat(
            vec([join(x, "_") for x in Iterators.product(BetweenFactorLevel...)]),
            inner = n * nWcomb,
        )
        BetweenFactorLabel = permutedims(hcat(split.(BetweenFactorLabel, "_")...))
    end

    # Within participant factor label
    if !ismissing(W)
        WithinFactorName = string.(collect('a':'z')[1:length(W)])
        WithinFactorLevel = [string.(WithinFactorName[i], 1:W[i]) for i = 1:length(W)]
        WithinFactorLabel = repeat(
            vec([join(x, "_") for x in Iterators.product(WithinFactorLevel...)]),
            outer = n * nBcomb,
        )
        WithinFactorLabel = permutedims(hcat(split.(WithinFactorLabel, "_")...))
    end

    # Participant label
    ParticipantNumber =
        ismissing(W) ? collect(1:n*nBcomb) : repeat(1:n*nBcomb, inner = nWcomb)
    ParticipantLabel =
        string.(
            "S",
            lpad.(ParticipantNumber, length(string(maximum(ParticipantNumber))), "0"),
        )

    # Cell means and cell SDs
    if ismissing(W)
        CellMeans = size(M) == (nBcomb,) ? M : repeat([M[1]], nBcomb)
        CellSDs = size(SD) == (nBcomb,) ? SD : repeat([SD[1]], nBcomb)
    else
        CellMeans = size(M) == (nBcomb, nWcomb) ? M : repeat([M[1]], nBcomb, nWcomb)
        CellSDs = size(SD) == (nBcomb, nWcomb) ? SD : repeat([SD[1]], nBcomb, nWcomb)
    end
    # Correlation Matrix
    if ismissing(W)                          # No within participant factor
        Rr = repeat([[1]], nBcomb)
    elseif R isa Number                      # Scaler
        Rm = repeat([R], nWcomb, nWcomb)
        Rm[diagind(Rm)] .= 1
        Rr = repeat([Rm], nBcomb)
    elseif R isa Array{<:Number,2}          # Matrix
        Rr = repeat([R], nBcomb)
    elseif R isa Array{<:Array{<:Number,2}} # Vector of matries
        Rr = R
    end

    # Data
    Data = Float64[]
    for between = 1:nBcomb
        Cell = rand(MvNormal(Rr[between]), n)
        nWcomb = ismissing(W) ? 1 : nWcomb
        for within = 1:nWcomb
            Cell[within, 1:n] .=
                Cell[within, 1:n] .* CellSDs[between, within] .+ CellMeans[between, within]
        end
        push!(Data, Cell...)
    end

    if ismissing(W)
        df = DataFrame(
            [ParticipantLabel BetweenFactorLabel Data],
            ["Participant", BetweenFactorName..., "DV"],
        )
    else
        df = DataFrame(
            [ParticipantLabel BetweenFactorLabel WithinFactorLabel Data],
            ["Participant", BetweenFactorName..., WithinFactorName..., "DV"],
        )
    end

    df[!, :DV] = convert.(Float64, df[:, :DV])

    return df

end # end of the function


function Hypothesis()
    df = SimulateData()
    fm = @formula(DV ~ 1 + A * a * b)
    ff = lm(
        fm,
        df,
        contrasts = Dict(:A => DummyCoding(), :a => EffectsCoding(), :b => EffectsCoding()),
    )
    propertynames(ff)
    ff.mf.f # formula
    coeftable(ff)
    mm = modelmatrix(ff.mf)

    names = coefnames(ff)
    hpm = StatsModels.hypothesis_matrix(mm, intercept = false)

    res = hcat(df, DataFrame(permutedims(hpm), names))
end
