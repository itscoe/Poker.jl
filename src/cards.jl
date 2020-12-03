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

function Base.:-(x::Hand, y::Hand)
    new_hand = Array{Card}(undef, 0)
    for card in x
        if !(card in y)
            push!(new_hand, card)
        end
    end
    return Hand(new_hand)
end

function deal!(deck::Hand, n::Integer)
    new_hand = Array{Card}(undef, n)
    order = randperm(length(deck))
    for i = 1:n
        new_hand[i] = deck[order[i]]
    end
    deck -= new_hand
    return Hand(new_hand)
end

function cards(hand::Hand)
    cards_to_return = Array{Card}(undef, length(hand))
    for i = 1:length(hand)
        cards_to_return[i] = hand[i]
    end
    return cards_to_return
end

Base.:isless(x::Card, y::Card) = findfirst(isequal(x), fresh_deck_cards) <
    findfirst(isequal(y), fresh_deck_cards)

Base.:isless(x::Suit, y::Suit) = return x.i < y.i

function isflush(hand::Hand)
    if length(hand) != 5
        return false
    else
        return Cards.suit(hand[1]) == Cards.suit(hand[2]) ==
            Cards.suit(hand[3]) == Cards.suit(hand[4]) == Cards.suit(hand[5])
    end
end

to_string(hand::Hand) = join(map(x -> ranks[x],
    Cards.rank.(reverse(sort(cards(hand))))))

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

Base.:<(x::Hand, y::Hand) = isless(x, y)
Base.:>(x::Hand, y::Hand) = isless(y, x)
