require 'httparty'
require_relative './database.rb'
require_relative '../logging.rb'

module BetHandler

  attr_accessor :current_round

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
  end

  def reset_round
    Log.info "Round reset"
    this_round.map do |bet|
      user = User.find(id: bet.user_id)
      user.coins += bet.amount
      user.save

      "#{user.name}: You now have #{user.coins} jaggCoins! (Refunded #{bet.amount})"
    end.unshift "The round has been RESET!"
  end

  def payout(victory)
    Log.info "Payout started. victory == #{victory.inspect}"
    bets = victory ? bets_for : bets_against
    bets.map do |bet|
      payout = 2 * bet.amount
      user = User.find(id: bet.user_id)
      user.coins += payout
      user.save

      "#{user.name}: You now have #{user.coins} jaggCoins! (+ #{bet.amount})"
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
    user = User.get(username, is_subscriber?(username))

    if Bet.where(round: self.current_round, user_id: user.id).any?
      Log.info "Bet by #{username} rejected as duplicate"
      return Response.new.tap do |r|
        r.success = false
        r.messages = ["Sorry, you can only bet once per round!"]
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

      Log.info "Bet for #{amount} placed by #{username} on #{on_victory ? 'victory' : 'defeat'}"

      return Response.new.tap do |r|
        r.success = true
        r.messages = ["#{username}: Staking #{amount} jaggCoins on #{on_victory ? 'victory' : 'defeat'}. You have #{user.coins} remaining!"]
      end

    else
      Log.info "Bet by #{username} rejected for insufficient funds"

      return Response.new.tap do |r|
        r.success = false
        r.messages = ["#{username} Sorry, you don't have the funds to make that wager! You only have #{user.coins} jaggCoins in your piggy-bank."]
      end
    end
  end

  private

  def total_of bets
    bets.map(&:amount).inject(:+) || 0
  end

  def average_of bets
    amounts = bets.map(&:amount)
    amounts.inject(:+).to_f / amounts.count rescue 0
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
