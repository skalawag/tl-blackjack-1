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
human_name = "Human"
bot_name = 'Bot'

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

def display(human_name, human_score, human_hand, bot_name, bot_score,
            bot_hand, score, announce=false)
  if announce
    winner = get_winner(human_score, bot_score, human_name, bot_name)
    update_score(winner, score, bot_name, human_name)
  end
  fmt = "%-8s %-11s %-20s %5s\n"
  hline = "-" * 47 + "\n"
  system 'clear'
  printf(fmt, "Name", "Score", "Cards", "Total")
  printf("%-33s", hline)
  printf(fmt, human_name, human_score, human_hand.join(" "), score[:human].to_s)
  printf(fmt, bot_name, bot_score, bot_hand.join(" "), score[:bot].to_s)
  puts ""
  if announce
    if winner
      message(winner)
    else
      message()
    end
  end
end

def get_winner(human_score, bot_score, human_name, bot_name)
  case
  when human_score == bot_score
    return nil
  when bot_score == BUSTED ||
      human_score == BLACKJ ||
      (human_score != BUSTED && human_score > bot_score)
    return human_name
  else
    return bot_name
  end
end


def update_score(winner, score, bot_name, human_name)
  if winner == bot_name
    score[:bot] += 1
  elsif winner == human_name
    score[:human] += 1
  end
end



# Score
score = {human: 0, bot: 0}

###########
## run game
while true
  # deal the cards
  human_hand = deal_n(2, deck)
  bot_hand = deal_n(2, deck)

  # Scores
  human_score = evaluate_hand(human_hand, deck).max
  bot_score = evaluate_hand(bot_hand, deck).max

  # test blackjack for player
  human_score = BLACKJ if blackjack?(human_hand)

  # update display
  display(human_name, human_score, human_hand, bot_name, bot_score, bot_hand, score)



  # query player
  while human_score != BLACKJ
    puts "Hit or Stay? (h|s)"
    choice = gets.chomp.downcase
    while choice != 'h' && choice != 's'
      puts "Eh? Hit or Stay? (h|s)"
      choice = gets.chomp
    end
    if choice == 's'
      break
    elsif choice == 'h'
      human_hand << deal_n(1, deck).first
      human_score = evaluate_hand(human_hand, deck).max
      if human_score
        display(human_name, human_score, human_hand, bot_name, bot_score, bot_hand, score)
      else
        human_score = BUSTED
        break
      end
    end
  end

  # update display
  display(human_name, human_score, human_hand, bot_name, bot_score, bot_hand, score)

  # dealer's turn
  bot_score = BLACKJ if blackjack?(bot_hand)

  while bot_score != BLACKJ &&
      bot_score != BUSTED &&
      evaluate_hand(bot_hand, deck).max < 17 &&
      human_score != BUSTED
    bot_hand << deal_n(1, deck).first
    # update dealer score
    if bot_score = evaluate_hand(bot_hand, deck).max
      display(human_name, human_score, human_hand, bot_name, bot_score, bot_hand, score)
    else
      bot_score = BUSTED
    end
  end

  # announce winner or draw
  display(human_name, human_score, human_hand, bot_name,
          bot_score, bot_hand, score, announce=true)

  puts ""
  puts "Again? (y/n)"
  if gets.chomp != 'y'
    break
  end
end
