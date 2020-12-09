using ProgressMeter

"""
    +(self, table[, N])

Computes with N (default 1,000) Monte Carlo simulations the odds of the hand
winning the showdown given the cards shown on the table

"""
function calculate_odds(self::Hand, table::Hand; N = 1_000)
    wins = 0
    for i = 1:N
        deck = fresh_deck - self - table
        opp, deck = deal(deck, 2)
        extra_cards, deck = deal(deck, 5 - length(table))
        if opp + table + extra_cards < self + table + extra_cards
            wins += 1
        end
    end
    return wins / N
end

"""
    get_preflop_odds([N])

Computes with N (default 1,000) Monte Carlo simulations the odds of the each
starting hand winning the showdown given no cards shown on the table yet.
This table is optionally used to speed up game calculations.

"""
function get_preflop_odds(; N = 1000)
    preflop_odds = zeros(52, 52)
    @showprogress for i = 1:52, j = 1:52
        if i != j
            preflop_odds[i, j] = calculate_odds(
                Hand([fresh_deck_cards[i], fresh_deck_cards[j]]),
                Hand([]), N = N)
        end
    end
    return preflop_odds
end
