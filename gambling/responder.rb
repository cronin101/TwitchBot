require 'yaml'

require_relative './bet_handler.rb'

# For each supported scenario, this module responds by yielding an array of lines to reply with
module GamblingResponder
  extend self

  begin
    Config = YAML.load_file(__dir__ + '/jaggcoins_config.yaml')
  rescue
    Config = {}
  end

  attr_accessor :accept_bets

  def is_mod? sender
    Config['mods'].include? sender
  end

  def get_explanation
    yield [Config['explanation']]
  end

  def get_highscores
    yield User.order(Sequel.desc(:coins)).take(5)
        .each_with_index
        .map { |user, idx| "#{idx + 1}: #{user.name} (#{user.coins} jaggCoins)" }
  end

  def get_balance(name)
    user = User.get(name, BetHandler.is_subscriber?(name))
    yield ["#{name}: You have #{user.coins} jaggCoins!"]
  end

  def record_outcome(outcome_is_victory)
    if self.accept_bets
      yield ["Betting is still open! Did you forget to close it?"]
    else
      yield BetHandler.payout(outcome_is_victory)
    end
  end

  def enable_betting
    if !self.accept_bets
      self.accept_bets = true
      yield [
        "Betting is now OPEN!",
        'If you think Jaggerous will win the next match, type "!bet win <amount>"',
        'If you think Jaggerous will lose the next match, type "!bet lose <amount>"',
      ]
      BetHandler.start_new_round
    else
      yield ["Betting is already open!"]
    end
  end

  def disable_betting
    if self.accept_bets
      self.accept_bets = false
      yield ["Betting is now CLOSED!"].concat BetHandler.summarise_round
    else
      yield ["Betting is already closed!"]
    end
  end

  def place_bet(username, on_victory, amount)
    if amount.to_i.zero?
      yield ["#{username}: Don't be afraid to dream a little bigger, darling."]
    elsif self.accept_bets
      yield BetHandler.handle_bet(username, on_victory, amount).messages
    else
      yield ["#{username}: Betting is currently closed!"]
    end
  end
end

