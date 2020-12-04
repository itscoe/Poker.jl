# Here we're going to extend the functionality of Stefan Karpinski's Cards.jl

using Cards, Combinatorics, Random, CSV, DataFrames

const ranks = ['1', '2', '3', '4', '5', '6', '7', '8', '9',
        'T', 'J', 'Q', 'K', 'A']
const hand_rankings = convert(Array{String},
    CSV.read(joinpath(dirname(pathof(Poker)), "..", "data", "hand_ranks.csv"),
    DataFrame, header = false, types=repeat([String], 7462)))
const fresh_deck_cards = [2♣,   2♢,  2♡,  2♠,
                          3♣,   3♢,  3♡,  3♠,
                          4♣,   4♢,  4♡,  4♠,
                          5♣,   5♢,  5♡,  5♠,
                          6♣,   6♢,  6♡,  6♠,
                          7♣,   7♢,  7♡,  7♠,
                          8♣,   8♢,  8♡,  8♠,
                          9♣,   9♢,  9♡,  9♠,
                          10♣, 10♢, 10♡, 10♠,
                          J♣,   J♢,  J♡,  J♠,
                          Q♣,   Q♢,  Q♡,  Q♠,
                          K♣,   K♢,  K♡,  K♠,
                          A♣,   A♢,  A♡,  A♠]
const fresh_deck = Hand(fresh_deck_cards)

"""
    +(x, y)

Adds two hands together, combining their cards into a single hand. Probably more
akin to a union, but duplicate cards are not supported, which helps catch bugs
and ensures hands are exactly the length of the two inputs hands added.

# Examples
```jldoctest
julia> deal(fresh_deck, 2)[1] + deal(fresh_deck, 2)[1]
Cards.Hand with 4 elements:
[...]
```
"""
function Base.:+(x::Hand, y::Hand)
    new_hand = Array{Card}(undef, 0)
    for card in x
        push!(new_hand, card)
    end
    for card in y
        push!(new_hand, card)
    end
    return Hand(new_hand)
end

"""
    -(x, y)

Subtracts the cards from one hand from another. Subtraction more closely follows
set theory's subtraction, as cards that are attempted to be subtracted that
aren't in the original hand are ignored. This should probably at least warn the
user for most poker-related use cases.

# Examples
```jldoctest
julia> fresh_deck - deal(fresh_deck, 2)[1]
Cards.Hand with 50 elements:
[...]
```
"""
function Base.:-(x::Hand, y::Hand)
    new_hand = Array{Card}(undef, 0)
    for card in x
        if !(card in y)
            push!(new_hand, card)
        end
    end
    return Hand(new_hand)
end

"""
    deal(deck, n)

Returns both a new hand of n cards, drawn without replacement from the deck,
and the deck without the cards that were drawn

# Examples
```jldoctest
julia> deal(fresh_deck, 2)[1]
Cards.Hand with 2 elements:
[...]
```
"""
function deal(deck::Hand, n::Integer)
    new_hand = Array{Card}(undef, n)
    order = randperm(length(deck))
    for i = 1:n
        new_hand[i] = deck[order[i]]
    end
    deck -= Hand(new_hand)
    return Hand(new_hand), deck
end

"""
    cards(hand)

Converts a Hand (from Cards.jl) to an array of cards

# Examples
```jldoctest
julia> cards(deal(fresh_deck, 2)[1])
2-element Array{Cards.Card,1}:
[...]
```
"""
function cards(hand::Hand)
    cards_to_return = Array{Card}(undef, length(hand))
    for i = 1:length(hand)
        cards_to_return[i] = hand[i]
    end
    return cards_to_return
end

"""
    isless(x, y)

Compares if a card is less than another card based on its position in a fresh
deck. This isn't actually used in Poker.jl right now, but is probably a handy
functionality for any extension of Cards.jl

# Examples
```jldoctest
julia> deal(fresh_deck, 2)[1][1] < deal(fresh_deck, 2)[1][1] || true
true
```
"""
Base.:isless(x::Card, y::Card) = findfirst(isequal(x), fresh_deck_cards) <
    findfirst(isequal(y), fresh_deck_cards)

"""
    isless(x, y)

Compares if the suit of a card is ranked lower than that of another card. This
isn't actually used in Poker.jl right now, but is probably a handy
functionality for any extension of Cards.jl
"""
Base.:isless(x::Suit, y::Suit) = return x.i < y.i

function isflush(hand::Hand)
    if length(hand) != 5
        return false
    else
        return Cards.suit(hand[1]) == Cards.suit(hand[2]) ==
            Cards.suit(hand[3]) == Cards.suit(hand[4]) == Cards.suit(hand[5])
    end
end

"""
    to_string(hand)

Compares if the suit of a card is ranked lower than that of another card. This
isn't actually used in Poker.jl right now, but is probably a handy
functionality for any extension of Cards.jl
"""
to_string(hand::Hand) = join(map(x -> ranks[x],
    Cards.rank.(reverse(sort(cards(hand))))))

"""
    isless(x, y)

Compares two hands to one another, using Texas Hold'em rules. Ties evaluate as
false. If larger hands are provided than five cards, the maximal combination of
five cards is used for the comparison.

# Examples
```jldoctest
julia> isless(deal(fresh_deck, 7)[1], deal(fresh_deck, 7)[1]) || true
true
```
"""
function Base.:isless(x::Hand, y::Hand)
    hand1 = length(x) > 5 ? maximum(Hand.(combinations(x, 5))) : x
    hand2 = length(y) > 5 ? maximum(Hand.(combinations(y, 5))) : y
    ranking1 = isflush(hand1) ? first(findall(isequal(to_string(hand1)),
        hand_rankings)) : last(findall(isequal(to_string(hand1)),
        hand_rankings))
    ranking2 = isflush(hand2) ? first(findall(isequal(to_string(hand2)),
        hand_rankings)) : last(findall(isequal(to_string(hand2)),
        hand_rankings))
    return ranking1 > ranking2
end

"""
    <(x, y)

Syntactic sugar for isless(x, y)

# Examples
```jldoctest
julia> deal(Poker.fresh_deck, 7)[1] < deal(Poker.fresh_deck, 7)[1] || true
true
```
"""
Base.:<(x::Hand, y::Hand) = isless(x, y)

"""
    <(x, y)

Syntactic sugar for isless(y, x)

# Examples
```jldoctest
julia> deal(Poker.fresh_deck, 7)[1] > deal(Poker.fresh_deck, 7)[1] || true
true
```
"""
Base.:>(x::Hand, y::Hand) = isless(y, x)
