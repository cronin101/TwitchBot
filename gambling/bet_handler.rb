require 'httparty'
require_relative './database.rb'
require_relative '../logging.rb'

module BetHandler

  attr_accessor :current_round, :has_paid_out

  extend self

  JagToken = YAML.load_file(__dir__ + '/../auth.yaml')['jag_token'] rescue ""

  def is_subscriber?(user)
    code = (HTTParty.get "https://api.twitch.tv/kraken/channels/jaggerous/subscriptions/#{user}?oauth_token=#{JagToken}").code
    Log.info "Status code for #{user} was #{code}"
    code == 200
  end

  def start_new_round
    Log.info "New round started"
    new_round = Round.create
    self.current_round = new_round.number
    self.has_paid_out = false
  end

  def reset_round
    Log.info "Round reset"
    (this_round.map do |bet|
      user = User.find(id: bet.user_id)
      user.coins += bet.amount
      user.save

      "#{user.name}: You are now rank #{user.rank} with #{user.coins} jaggCoins! (Refunded #{bet.amount})"
    end.unshift "The round has been RESET!").tap { |response| start_new_round }
  end

  def payout(victory)
    return "Payout has already occured!" if self.has_paid_out

    self.has_paid_out = true
    Log.info "Payout started. victory == #{victory.inspect}"
    bets = victory ? bets_for : bets_against
    bets.map do |bet|
      payout = 2 * bet.amount
      user = User.find(id: bet.user_id)
      user.coins += payout
      user.save

      "#{user.name}: You are now rank #{user.rank} with #{user.coins} jaggCoins! (+ #{bet.amount})"
    end.unshift "The round has ended in #{victory ? 'VICTORY' : 'DEFEAT'}!"
  end

  def summarise_round
    case betting_trend
    when :no_bets then return ["No bets were placed during the last round!"]
    when :tie then split_summary
    when :victory then optimistic_summary
    when :loss then pessimistic_summary
    end <<
      "#{total_of bets_for} jaggCoins placed on Victory (average: #{average_of bets_for}), #{total_of bets_against} placed on Defeat (average: #{average_of bets_against})!"
  end

  Response = Struct.new(:success, :messages)

  def handle_bet(username, on_victory, amount)
    amount = amount.to_i

    # User needs to be found or created.
    user = User.get(username, -> { is_subscriber?(username) })

    # User can only make one bet per round
    return duplicate_bet_response(username) if has_made_bet_this_round?(user)

    # User needs to have enough coins to make the bet
    if user.coins >= amount.to_i
      new_bet_response(user, on_victory, amount)
    else
      insufficient_funds_response(username, user.coins)
    end
  end

  private

  def duplicate_bet_response(username)
    Log.info "Bet by #{username} rejected as duplicate"
    Response.new(false, ["#{username}: Sorry, you can only bet once per round!"])
  end

  def new_bet_response(user, on_victory, amount)
    Bet.create do |bet|
      bet.user_id = user.id
      bet.round = self.current_round
      bet.is_on_victory = on_victory
      bet.amount = amount
    end

    user.coins -= amount
    user.save

    Log.info "Bet for #{amount} placed by #{user.name} on #{on_victory ? 'victory' : 'defeat'}"
    Response.new(true, ["#{user.name}: Staking #{amount} jaggCoins on #{on_victory ? 'victory' : 'defeat'}. You have #{user.coins} remaining!"])
  end

  def insufficient_funds_response(username, coins)
    Log.info "Bet by #{username} rejected for insufficient funds"
    Response.new(false, ["#{username} Sorry, you don't have the funds to make that wager! You only have #{coins} jaggCoins in your piggy-bank."])
  end

  def has_made_bet_this_round?(user)
    Bet.where(round: self.current_round, user_id: user.id).any?
  end

  def total_of bets
    bets.map(&:amount).inject(:+) || 0
  end

  def average_of bets
    amounts = bets.map(&:amount)
    (amounts.inject(:+).to_f / amounts.count rescue 0).round(2)
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

  def betting_trend
    if this_round.count == 0
      :no_bets
    elsif bets_for.count == bets_against.count
      :tie
    elsif bets_for.count > bets_against.count
      :victory
    else
      :loss
    end
  end

  def split_summary
    ["It's looking pretty uncertain with an even split of #{this_round.count} people.",
     "Half (#{bets_for.count}) expect a win; the same number (#{bets_against.count}) predict a loss!"]
  end

  def optimistic_summary
    ["Most people (#{bets_for.count} / #{this_round.count}) believe that Jaggerous has what it takes to win the next game."]
  end

  def pessimistic_summary
    ["There is a distinct lack of confidence in Jaggerous for the next game, with (#{bets_against.count} / #{this_round.count}) people expecting a loss."]
  end
end
