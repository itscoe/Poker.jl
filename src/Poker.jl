module Poker

include("cards.jl")
include("odds.jl")
include("game.jl")

export +, -, >, <, deal, cards, isless, isflush, to_string, calculate_odds,
    get_preflop_odds, bet, get_return, get_returns, get_returns_table

end
