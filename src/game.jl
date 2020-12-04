using Distributions, ProgressMeter

"""
    bet(dealer, self_strat, opp_strat, self_prob, opp_prob, self_return,
        opp_return, pot, big_blind)

Processes the bets for the players, given thresholds at which each player will
not put more money into the game, and the calculated odds of each player
winning the showdown. Also returns whether the whole get_return function should
return

"""
function bet(dealer::String, self_strat::Float64, opp_strat::Float64,
  self_prob::Float64, opp_prob::Float64, self_return::Float64,
  opp_return::Float64, pot::Float64, big_blind::Float64)
    to_return = false
    if dealer == "opp"
        if opp_prob > opp_strat
            if self_prob < self_strat
                opp_return += pot
                to_return = true
            else
                opp_return -= 2 * big_blind
                self_return -= 2 * big_blind
                pot += 4 * big_blind
            end
        else
            if self_prob > self_strat
                self_return += pot
                to_return = true
            end
        end
    else
        if self_prob > self_strat
            if opp_prob < opp_strat
                self_return += pot
                to_return = true
            else
                opp_return -= 2 * big_blind
                self_return -= 2 * big_blind
                pot += 4 * big_blind
            end
        else
            if opp_prob > opp_strat
                opp_return += pot
                to_return = true
            end
        end
    end
    return to_return, self_return, opp_return, pot
end

"""
    get_return(self_strat, opp_strat[, preflop_odds_table])

Returns the self return after 1 simulated game, given the singular thresholds
at which either player will not put more money into the game. Optional
optimization is available by specifying a pre-calculated preflop odds table

"""
function get_return(self_strat::Float64, opp_strat::Float64;
  preflop_odds_table::Array{Float64, 2} = zeros(52, 52))
    using_preflop_odds = preflop_odds_table == zeros(52, 52)
    big_blind, small_blind = 1.0, 0.5
    self_return, opp_return, pot = 0.0, 0.0, 0.0

    deck = fresh_deck
    table, self_hand, opp_hand = Hand([]), Hand([]), Hand([])
    dealer = rand(["self", "opp"])
    if dealer == "opp" # Opponent deals
        self_return -= big_blind
        opp_return -= small_blind
        self_hand, deck = deal(deck, 2)
        opp_hand, deck = deal(deck, 2)
    else # Self deals
        self_return -= small_blind
        opp_return -= big_blind
        opp_hand, deck = deal(deck, 2)
        self_hand, deck = deal(deck, 2)
    end
    pot += big_blind + small_blind
    if using_preflop_odds
        self_prob, opp_prob = pre_flop_odds_table[
            findfirst(isequal(self_hand[1]), fresh_deck_cards),
            findfirst(isequal(self_hand[2]), fresh_deck_cards)],
            pre_flop_odds_table[
            findfirst(isequal(opp_hand[1]), fresh_deck_cards),
            findfirst(isequal(opp_hand[2]), fresh_deck_cards)]
    else
        self_prob, opp_prob = calculate_odds(self_hand, table, N = 100),
            calculate_odds(opp_hand, table, N = 100)
    end

    # First round of betting
    to_return, self_return, opp_return, pot = bet(dealer, self_strat, opp_strat,
        self_prob, opp_prob, self_return, opp_return, pot, big_blind)
    to_return && return self_return

    # Flop
    dealt, deck = deal(deck, 3)
    table += dealt
    self_prob, opp_prob = calculate_odds(self_hand, table, N = 100),
        calculate_odds(opp_hand, table, N = 100)

    # Second round of betting
    to_return, self_return, opp_return, pot = bet(dealer, self_strat, opp_strat,
        self_prob, opp_prob, self_return, opp_return, pot, big_blind)
    to_return && return self_return

    # Turn
    dealt, deck = deal(deck, 1)
    table += dealt
    self_prob, opp_prob = calculate_odds(self_hand, table, N = 100),
        calculate_odds(opp_hand, table, N = 100)

    # Third round of betting
    to_return, self_return, opp_return, pot = bet(dealer, self_strat, opp_strat,
        self_prob, opp_prob, self_return, opp_return, pot, big_blind)
    to_return && return self_return

    # River
    dealt, deck = deal(deck, 1)
    table += dealt
    self_prob, opp_prob = calculate_odds(self_hand, table, N = 100),
        calculate_odds(opp_hand, table, N = 100)

    # Fourth and final round of betting
    to_return, self_return, opp_return, pot = bet(dealer, self_strat, opp_strat,
        self_prob, opp_prob, self_return, opp_return, pot, big_blind)
    to_return && return self_return

    # Showdown
    if (self_hand + table) < (opp_hand + table)
        opp_return += pot
    elseif (opp_hand + table) < (self_hand + table)
        self_return += pot
    else
        self_return += pot / 2
        opp_return += pot / 2
    end
    return self_return
end

"""
    get_return(self_strat, opp_strat[, preflop_odds_table])

Returns the self return after 1 simulated game, given the multiple thresholds
(one for each round of betting; ie, 4) at which either player will not put more
money into the game. Optional optimization is available by specifying a
pre-calculated preflop odds table

"""
function get_return(self_strat::Array{Float64}, opp_strat::Array{Float64};
  preflop_odds_table::Array{Float64, 2} = zeros(52, 52))
    using_preflop_odds = preflop_odds_table == zeros(52, 52)
    big_blind, small_blind = 1.0, 0.5
    self_return, opp_return, pot = 0.0, 0.0, 0.0

    deck = fresh_deck
    table, self_hand, opp_hand = Hand([]), Hand([]), Hand([])
    dealer = rand(["self", "opp"])
    if dealer == "opp" # Opponent deals
        self_return -= big_blind
        opp_return -= small_blind
        self_hand, deck = deal(deck, 2)
        opp_hand, deck = deal(deck, 2)
    else # Self deals
        self_return -= small_blind
        opp_return -= big_blind
        opp_hand, deck = deal(deck, 2)
        self_hand, deck = deal(deck, 2)
    end
    pot += big_blind + small_blind
    if using_preflop_odds
        self_prob, opp_prob = pre_flop_odds_table[
            findfirst(isequal(self_hand[1]), fresh_deck_cards),
            findfirst(isequal(self_hand[2]), fresh_deck_cards)],
            pre_flop_odds_table[
            findfirst(isequal(opp_hand[1]), fresh_deck_cards),
            findfirst(isequal(opp_hand[2]), fresh_deck_cards)]
    else
        self_prob, opp_prob = calculate_odds(self_hand, table, N = 100),
            calculate_odds(opp_hand, table, N = 100)
    end

    # First round of betting
    @inbounds to_return, self_return, opp_return, pot = bet(dealer,
        self_strat[1], opp_strat[1], self_prob, opp_prob, self_return,
        opp_return, pot, big_blind)
    to_return && return self_return

    # Flop
    dealt, deck = deal(deck, 3)
    table += dealt
    self_prob, opp_prob = calculate_odds(self_hand, table, N = 100),
        calculate_odds(opp_hand, table, N = 100)

    # Second round of betting
    @inbounds to_return, self_return, opp_return, pot = bet(dealer,
        self_strat[2], opp_strat[2], self_prob, opp_prob, self_return,
        opp_return, pot, big_blind)
    to_return && return self_return

    # Turn
    dealt, deck = deal(deck, 1)
    table += dealt
    self_prob, opp_prob = calculate_odds(self_hand, table, N = 100),
        calculate_odds(opp_hand, table, N = 100)

    # Third round of betting
    @inbounds to_return, self_return, opp_return, pot = bet(dealer,
        self_strat[3], opp_strat[3], self_prob, opp_prob, self_return,
        opp_return, pot, big_blind)
    to_return && return self_return

    # River
    dealt, deck = deal(deck, 1)
    table += dealt
    self_prob, opp_prob = calculate_odds(self_hand, table, N = 100),
        calculate_odds(opp_hand, table, N = 100)

    # Fourth and final round of betting
    @inbounds to_return, self_return, opp_return, pot = bet(dealer,
        self_strat[4], opp_strat[4], self_prob, opp_prob, self_return,
        opp_return, pot, big_blind)
    to_return && return self_return

    # Showdown
    if (self_hand + table) < (opp_hand + table)
        opp_return += pot
    elseif (opp_hand + table) < (self_hand + table)
        self_return += pot
    else
        self_return += pot / 2
        opp_return += pot / 2
    end
    return self_return
end

function get_returns(self_strat::Float64, opp_strat::Float64;
  preflop_odds_table::Array{Float64, 2} = zeros(52, 52), N = 5_000)
    return mean(map(x -> get_return(self_strat, opp_strat,
        preflop_odds_table = preflop_odds_table), 1:N))
end

"""
    get_returns(self_strat, opp_strat[, preflop_odds_table, N])

Wrapping of get_return, but the mean of N (default 5,000) times

"""
function get_returns(self_strat::Array{Float64}, opp_strat::Array{Float64};
  preflop_odds_table::Array{Float64, 2} = zeros(52, 52), N = 5_000)
    return mean(map(x -> get_return(self_strat, opp_strat,
        preflop_odds_table = preflop_odds_table), 1:N))
end

"""
    get_returns(self_strat, opp_strat[, preflop_odds_table, N])

Wrapping of get_return, but the mean of N (default 100) times

"""
function get_returns(self_strat::Array{Float64};
  preflop_odds_table::Array{Float64, 2} = zeros(52, 52), N = 100)
    return mean(map(x -> get_return(self_strat,
        [rand(), rand(), rand(), rand()],
        preflop_odds_table = preflop_odds_table), 1:N))
end

"""
    get_returns_table([preflop_odds_table, N])

Calculation of a table of average returns across a gamut of singular threshold
strategies, with the optional optimization of pre-calculating the preflop odds
table. Default N is 5,000 simulations per pair of strategies (total 50,000,000
games)

"""
function get_returns_table(;
  preflop_odds_table::Array{Float64, 2} = zeros(52, 52), N = 5_000)
    returns_table = zeros(100, 100)
    @showprogress for i = 1:100, j = 1:100
        if i != j
            returns_table[i, j] = get_returns(i / 100, j / 100,
                preflop_odds_table = preflop_odds_table, N = N)
        end
    end
    return returns_table
end
