
module Console
  def self.clear_screen
    system('cls')
    system('clear')
    display_banner("Let's Play Blackjack!")
  end

  def self.get_input(msg = nil)
    puts "\n~> #{msg} :" unless msg == nil
    gets.chomp.to_s
  end

  def self.display_banner(msg)
    spacer = ''
    spacer2 = ''
    spacer3 = ''
    len = msg.length.to_i
    for i in 1..len do
      spacer += '─'
    end
    for i in 1..10 do
      spacer2 += '─'
      spacer3 += ' '
    end
    puts "┌#{spacer2}#{spacer}#{spacer2}┐"
    puts "│#{spacer3}#{msg}#{spacer3}│"
    puts "└#{spacer2}#{spacer}#{spacer2}┘\n\n"
  end
end

class Card
  attr_reader :suit, :value

  def initialize(suit, value)
    @suit = suit
    @value = value
    @lines = Array.new(5)
  end

  def lines
    spacer = ' '
    spacer = '' if value.to_s.length == 2
    @lines[0] = "╔═════╗"
    @lines[1] = "║#{value} #{spacer} #{suit}║"
    @lines[2] = "║     ║"
    @lines[3] = "║#{suit} #{spacer} #{value}║"
    @lines[4] = "╚═════╝"
    return @lines
  end

  def self.suits
    ['♣', '♦', '♥', '♠']
  end

  def self.values
    ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
  end
end

class Deck
  attr_reader :cards

  def initialize
    build
  end

  def build
    @cards = []
    Card.suits.each do |suit|
      Card.values.each do |value|
        @cards.push(Card.new(suit, value))
      end
    end
  end

  def shuffle
    cards.shuffle!
  end

  def deal_card
    card = cards.sample
    cards.delete(card)
    return card
  end
end

class Player
  attr_accessor :name, :money, :bet, :cards

  def initialize
    @name = ''
    @money = 0.0
    @bet = 0.0
    @cards = []
  end

  def set_name
    @name = ''
    @name = Console.get_input("What's your name?") until name != ''
  end

  def set_money
    @money = 0.0
    @money = Console.get_input("Hello, #{name}! How much would you like to play with today? (e.g. 500)").to_f until money > 0
  end

  def set_bet
    @bet = 0.0
    @bet = Console.get_input("How much would you like to bet this hand? [Cash: $#{money}]").to_f until bet > 0 && bet <= money
    @money -= bet
  end

  def reset_cards
    @cards = []
  end

  def deal_card(deck)
    cards.push(deck.deal_card)
  end

  def display(masked = false)
    puts "#{name}\t\tCash: $#{money}\t\tBet: $#{bet}"
    display_cards(masked)
  end

  def display_cards(masked = false)
    line = Array.new(5)
    for i in 0..4 do
      line[i] = ''
    end

    if masked
      line[0] = "╔═════╗"
      line[1] = "║▒▒▒▒▒║"
      line[2] = "║▒▒▒▒▒║"
      line[3] = "║▒▒▒▒▒║"
      line[4] = "╚═════╝"
    end

    masked_flag = masked
    cards.each do |card|
      for i in 0..4 do
        line[i] += card.lines[i] unless masked_flag
      end
      masked_flag = false
    end

    line[2] += "\tTotal: #{total}" unless masked

    for i in 0..4 do
      puts line[i]
    end
  end

  def total
    total = 0
    @cards.each do |card|
      x = card.value
      case x
        when 'A'
          total += 11
        when 'J', 'Q', 'K'
          total += 10
        else
          total += x.to_i
      end
    end

    # If the player has an ace, we don't want to push them over 21, so we'll subtract 10 to compensate
    @cards.each do |card|
      x = card.value
      if x == 'A'
        total -= 10 if total > 21
      end
    end

    return total
  end

  def process_turn(game)
    if total < 21
      options = { 'h' => 'Hit', 's' => 'Stay' }
      choice = nil
      choice = options[Console.get_input('Hit or Stay? (h/s)').downcase] until choice != nil
      if choice == options['h']
        deal_card(game.deck)
        Console.clear_screen
        game.display_table(true)
        process_turn(game)
      end
    end
  end
end

class Dealer < Player
  def initialize
    @name = 'Dealer'
    @cards = []
  end

  def display(masked = false)
    puts "#{name}"
    display_cards(masked)
  end

  def process_turn(game)
    deal_card(game.deck) until total >= 17
  end
end

class Game
  attr_reader :player, :dealer, :deck

  def initialize
    @player = Player.new
    @dealer = Dealer.new
    @deck = Deck.new
    deck.shuffle
  end

  def run
    Console.clear_screen
    player.set_name
    Console.clear_screen
    player.set_money
    Console.clear_screen

    while player.money > 0 do
      @deck.build
      @deck.shuffle
      player.set_bet
      Console.clear_screen

      # Initial Deal
      player.reset_cards
      dealer.reset_cards
      2.times { player.deal_card(deck); dealer.deal_card(deck) }

      display_table(true)

      player.process_turn(self)
      dealer.process_turn(self)
      Console.clear_screen

      check_for_outcome
      display_table
    end
  end

  def check_for_outcome
    if dealer.total == 21 && player.total < 21
      puts 'Dealer has blackjack :('
    elsif player.total > 21
      puts 'Bust :('
    elsif dealer.total == player.total
      puts 'Game is a draw :|'
      payout(1)
    elsif player.total == 21
      puts 'Blackjack!'
      payout(3)
    elsif dealer.total > 21
      puts 'Dealer busts :)'
      payout(2)
    elsif player.total < 21 && dealer.total < player.total
      puts 'Player wins :)'
      payout(2)
    elsif dealer.total > player.total
      puts 'Dealer wins :('
    end
    puts "\n───────────────────────────────────────────\n\n"
  end

  def display_table(masked = false)
    dealer.display(masked)
    puts ''
    player.display
  end

  def payout(multiplier)
    amount = player.bet * multiplier
    player.money += amount
    puts "Payout: $#{amount} (#{multiplier}x)"
  end
end

blackjack_game = Game.new
blackjack_game.run