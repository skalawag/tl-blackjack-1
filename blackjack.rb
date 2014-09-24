require 'pry'

# 1. Both the player and dealer are dealt two cards to start the game.

# 2. Card Values

#    - ranks 2-10 (any suit) are their rank number.
#    - any face card is worth 10.
#    - aces are worth 1 or 11.
#    - 'Blackjack' is a face card + an Ace

# 3. After being dealt the initial 2 cards, the player goes first and
# can choose to either "hit" or "stay". If the player's cards sum up to
# be greater than 21, the player has "busted" and lost. If the sum is
# 21, then the player wins. If the sum is less than 21, then the player
# can choose to "hit" or "stay" again. If the player "hits", then repeat
# above, but if the player stays, then the player's total value is
# saved, and the turn moves to the dealer.

# 4. By rule, the dealer must hit until she has at least 17. If the
# dealer busts, then the player wins. If the dealer, hits 21, then the
# dealer wins. If, however, the dealer stays, then we compare the sums
# of the two hands between the player and dealer; higher value wins.

# Bonus:
# 1. Save the player's name, and use it throughout the app.
# 2. Ask the player if he wants to play again, rather than just exiting.
# 3. Save not just the card value, but also the suit.
# 4. Use multiple decks to prevent against card counting players.

BUSTED = "Busted!"
BLACKJ = "Blackjack!"

vars = {human_name: "Human", human_score: 0, human_total: 0, human_hand: nil,
  bot_name: "Bot", bot_score: 0, bot_total: 0, bot_hand: nil}

def make_deck()
  cards = "AJQKT98765432".chars.product("csdh".chars).map { |c| c.join }
  deck = {}
  cards.each do |c|
    if c.start_with?('A')
      deck[c] = {val: 11, live: true}
    elsif c.start_with?('K') || c.start_with?('Q') || c.start_with?('J') || c.start_with?('T')
      deck[c] = {val: 10, live: true}
    else
      deck[c] = {val: c[0].to_i, live: true}
    end
  end
  deck
end

deck = make_deck()

def deal_n(n, cards)
  available_cards = cards.select { |k,v| v[:live] }
  hand = available_cards.keys.sample(n)
  cards[hand.first][:live] = false
  cards[hand.last][:live] = false
  hand
end

# Evaluating hands with aces is the hard part of all this. By default,
# aces are worth eleven in the deck hash. But here we have to treat
# them specially. An ace in a hand means that hand has two possible
# values, two aces means up to four values (with duplication), and so
# on. This solution is possibly not very rubyesque, but the recursion
# is natural in this situation.
def recursive_valuation(vals, res=[0])
  if vals.empty?
    res.map { |score| score if score <= 21}.select{|s| not s.nil?}.uniq.sort
  elsif vals.first < 11
    recursive_valuation(vals[1..-1], res.map { |v| v + vals.first })
  else
    # number of hands doubles when we encounter an ace
    res = res.map { |v| v + 11 } + res.map { |v| v + 1 }
    recursive_valuation(vals[1..-1], res)
  end
end

def evaluate_hand(hand, deck)
  recursive_valuation(hand.map { |c| deck[c][:val] })
end

def blackjack?(hand)
  if hand.length > 2
    return false
  else
    sorted = hand.sort
    if sorted.first[0].start_with?('A') && sorted.last[0] =~ /K|Q|J|T/
      return true
    end
  end
end

def message(winner=false)
  if winner
    puts "#{winner} has won!"
  else
    puts "The game is a tie!"
  end
end

def display(vars={}, announce=false)
  if announce
    winner = get_winner(vars)
    update_score(winner, vars)
  end
  fmt = "%-8s %-11s %-20s %5s\n"
  hline = "-" * 47 + "\n"
  system 'clear'
  printf(fmt, "Name", "Score", "Cards", "Total")
  printf("%-33s", hline)
  printf(fmt, vars[:human_name], vars[:human_score], vars[:human_hand].join(" "), vars[:human_total].to_s)
  printf(fmt, vars[:bot_name], vars[:bot_score], vars[:bot_hand].join(" "), vars[:bot_total].to_s)
  puts ""
  if announce
    if winner
      message(winner)
    else
      message()
    end
  end
end

def get_winner(vars={})
  case
  when vars[:human_score] == vars[:bot_score]
    return nil
  when vars[:bot_score] == BUSTED ||
      vars[:human_score] == BLACKJ ||
      (vars[:human_score] != BUSTED && vars[:human_score] > vars[:bot_score])
    return vars[:human_name]
  else
    return vars[:bot_name]
  end
end

def update_score(winner, vars={})
  if winner == vars[:bot_name]
    vars[:bot_total] += 1
  elsif winner == vars[:human_name]
    vars[:human_total] += 1
  end
end



# Score
score = {human: 0, bot: 0}

###########
## run game
while true
  # deal the cards
  vars[:human_hand] = deal_n(2, deck)
  vars[:bot_hand] = deal_n(2, deck)

  # Scores
  vars[:human_score] = evaluate_hand(vars[:human_hand], deck).max
  vars[:bot_score] = evaluate_hand(vars[:bot_hand], deck).max

  # test blackjack for player
  vars[:human_score] = BLACKJ if blackjack?(vars[:human_hand])

  # update display
  display(vars)



  # query player
  while vars[:human_score] != BLACKJ
    puts "Hit or Stay? (h|s)"
    choice = gets.chomp.downcase
    while choice != 'h' && choice != 's'
      puts "Eh? Hit or Stay? (h|s)"
      choice = gets.chomp
    end
    if choice == 's'
      break
    elsif choice == 'h'
      vars[:human_hand] << deal_n(1, deck).first
      vars[:human_score] = evaluate_hand(vars[:human_hand], deck).max
      if vars[:human_score]
        display(vars)
      else
        vars[:human_score] = BUSTED
        break
      end
    end
  end

  # update display
  display(vars)

  # dealer's turn
  vars[:bot_score] = BLACKJ if blackjack?(vars[:bot_hand])

  while vars[:bot_score] != BLACKJ &&
      vars[:bot_score] != BUSTED &&
      evaluate_hand(vars[:bot_hand], deck).max < 17 &&
      vars[:human_score] != BUSTED
    vars[:bot_hand] << deal_n(1, deck).first
    # update dealer score
    if vars[:bot_score] = evaluate_hand(vars[:bot_hand], deck).max
      display(vars)
    else
      vars[:bot_score] = BUSTED
    end
  end

  # announce winner or draw
  display(vars, announce=true)

  puts ""
  puts "Again? (y/n)"
  if gets.chomp == 'y'
    deck = make_deck()
  else
    break
  end
end
