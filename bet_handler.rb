require_relative './database.rb'

module BetHandler

  attr_accessor :current_round

  extend self

  def start_new_round
    new_round = Round.create
    self.current_round = new_round.number
  end

  def this_round
    Bet.where(round: self.current_round)
  end

  def bets_for
    this_round.where(is_on_victory: true)
  end

  def bets_against
    this_round.where(is_on_victory: false)
  end

  def payout(m, victory)
    bets = victory ? bets_for : bets_against
    bets.each do |bet|
      payout = 2 * bet.amount
      user = User.find(id: bet.user_id)
      user.coins += payout
      user.save

      m.reply "#{user.name}: You now have #{user.coins} jaggCoins! (+ #{bet.amount})"
    end

  end

  def summarise_round
    round = Bet.where(round: self.current_round)

    if round.count == 0
      return ["No bets were placed during the last round!"]
    elsif bets_for.count == bets_against.count
      status = "It's looking pretty uncertain with an even split of #{round.count} people. Half (#{bets_for.count}) expect a win; the same number (#{bets_against.count}) predict a loss!"
    elsif bets_for.count > bets_against.count
      status = "Most people (#{bets_for.count} / #{round.count}) believe that Jaggerous has what it takes to win the next game."
    else
      status = "There is a distinct lack of confidence in Jaggerous for the next game, with (#{bets_against.count} / #{round.count}) people expecting a loss."
    end

    total   = ->(ary) { ary.map(&:amount).inject(:+) || 0 }
    average = ->(ary) { ary.map(&:amount).map(&:to_f).inject(:+) / ary.count.to_f rescue 0 }

    return [status] << "#{total.(bets_for)} jaggCoins placed on Victory (average: #{average.(bets_for)}), #{total.(bets_against)} placed on Defeat (average: #{average.(bets_against)})!"
  end

  def handle_bet(username, on_victory, amount, response_class)
    amount = amount.to_i

    # User needs to be found or created.
    user = User.get(username)

    if Bet.where(round: self.current_round, user_id: user.id).any?
      return response_class.new.tap do |r|
        r.success = false
        r.message = "Sorry, you can only bet once per round!"
      end
    end

    # User needs to have enough coins to make the bet
    if user.coins >= amount.to_i
      Bet.create do |bet|
        bet.user_id = user.id
        bet.round = self.current_round
        bet.is_on_victory = on_victory
        bet.amount = amount
      end

      user.coins -= amount
      user.save

      return response_class.new.tap do |r|
        r.success = true
        r.message = "#{user.name}: Staking #{amount} jaggCoins on #{on_victory ? 'victory' : 'defeat'}. You have #{user.coins} remaining!"
      end

    else

      return response_class.new.tap do |r|
        r.success = false
        r.message = "Sorry, you don't have the funds to make that wager! You only have #{user.coins} jaggCoins in your piggy-bank."
      end
    end
  end
end
