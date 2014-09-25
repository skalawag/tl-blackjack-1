## A much simplified version 2 of this, begun from scratch after
## reading the solution.

def make_deck()
  "AJQKT98765432".chars.product("csdh".chars).map { |c| c.join }
end

def blackjack?(cards)
  cards.length == 2 &&
    cards.sort.first[0] == 'A' &&
    cards.sort.last[0] =~ /K|Q|J|T/
end

def eval_hand(cards)
  if blackjack?(cards)
    return [100]
  end
  # otherwise, total card values
  total = [0]
  ranks = cards.map {|c| c[0]}
  ranks.each do |c|
    if c == 'A'
      total[0] += 11
    elsif c.to_i == 0
      total[0] += 10
    else
      total[0] += c.to_i
    end
  end
  # take account of aces
  ranks.count('A').times do
    total = total + total.map { |s| s - 10 }
  end
  total = total.select { |n| n < 22 }.reverse.uniq
  # check if player went bust
  if total.empty?
    return [-1]
  else
    return total
  end
end

def prep_score(eval_result, harden=false)
  if eval_result == [-1]
    return "Bust!"
  elsif eval_result == [100]
    return "Blackjack!"
  elsif eval_result.length == 1
    return eval_result[0]
  elsif harden
    return eval_result.max
  else
    return eval_result.map {|i| i.to_s}.join("/")
  end
end

def display(human_hand, bot_hand, h_name="Human", show_bot=false, harden=false)
  system 'clear'
  h_score = prep_score(eval_hand(human_hand), harden)
  b_score = prep_score(eval_hand(bot_hand), harden)
  fmt = "%-8s %-11s %-20s\n"
  hline = "-" * 33 + "\n"
  printf(fmt, "Player", "Score", "Hand")
  puts hline
  printf(fmt, h_name, h_score, human_hand.join(" "))
  if not show_bot
    printf(fmt, "Bot", "??", "X X")
  else
    printf(fmt, "Bot", b_score, bot_hand.join(" "))
  end
  puts ""
end

puts "Enter your name:"
h_name = gets.chomp

while true
  cards = make_deck()

  # deal initial cards
  h_hand = cards.shuffle!.pop(2)
  b_hand = cards.shuffle!.pop(2)

  # test for backjack
  if blackjack?(h_hand)
    if blackjack?(b_hand)
      puts "It's a tie!"
      display(h_hand, b_hand, h_name=h_name, show_bot=true)
    else
      puts "Human has won!"
      display(h_hand, b_hand, h_name=h_name, show_bot=true)
    end
  elsif blackjack?(b_hand)
    puts "Bot has won!"
    display(h_hand, b_hand, h_name=h_name, show_bot=true)
  end

  # if we haven't displayed anything yet, we should do so now.
  display(h_hand, b_hand, h_name=h_name)

  if not blackjack?(h_hand)
    begin
      puts "Hit or Stand? (h/s)"
      choice = gets.chomp.downcase
      while choice != 'h' && choice != 's'
        puts "Eh? Hit or Stand? (h/s)"
        choice = gets.chomp.downcase
      end
      if choice == 'h'
        h_hand << cards.shuffle!.pop
        display(h_hand, b_hand, h_name=h_name)
      end
    end until choice == 's' || eval_hand(h_hand) == [-1]
  end

  val = eval_hand(b_hand)[0]
  if (val < 17 && val > 0) && eval_hand(h_hand)[0] > 0
    begin
      b_hand << cards.shuffle!.pop
    end until eval_hand(b_hand) == [-1] || eval_hand(b_hand)[0] >= 17
    display(h_hand, b_hand, h_name=h_name, show_bot=true, harden=true)
  else
    display(h_hand, b_hand, h_name=h_name, show_bot=true, harden=true)
  end

  puts "Play again?"
  if gets.chomp != 'y'
    break
  end
end
