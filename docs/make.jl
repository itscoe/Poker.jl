using Poker
using Documenter

makedocs(;
    modules=[Poker],
    authors="itscoe",
    repo="https://github.com/itscoe/Poker.jl/blob/{commit}{path}#L{line}",
    sitename="Poker.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://itscoe.github.io/Poker.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/itscoe/Poker.jl.git",
)
