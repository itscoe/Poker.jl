module Poker

include("cards.jl")
include("odds.jl")
include("game.jl")

export Base.:+, Base.:-, deal!, cards, Base.:isless, isflush, to_string,
    Base.:<, Base.:>, calculate_odds, get_preflop_odds, bet, get_return,
    get_returns, get_returns_table

end
