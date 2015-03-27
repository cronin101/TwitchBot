require 'yaml'
require_relative './rubby_module.rb'

require_relative './bet_handler.rb'

class GamblingPlugin
  extend Rubby
  include Cinch::Plugin

  attr_accessor :accept_bets

  # Decorator to make commands fire only if triggered by a moderator
  def self.mod_command method_name
    method_name.tap do |name|
      body = instance_method name
      define_method name do |*args, &block|
        sender = args.first.user.name
        body.bind(self).call(*args, &block) if Config['mods'].include? sender
      end
    end
  end

  def self.mods_only name, block
    mod_command defn name, block
  end

  Config = YAML.load_file('./jaggcoins_config.yaml')

  # COMMANDS FOR EVERYONE: #
    match /jaggcoins$/i,     # Explanation of the betting system
      method: (defn :explanation, -> m { m.reply Config['explanation'] })

    match /bet\svictory\s(\d+)$/i, method: :bet_win
    match /bet\swin\s(\d+)$/i,  # Betting on a victory
      method: (defn :bet_win, ->(m, amount) { m.reply handle_user_bet(true, amount) })

    match /bet\sloss\s(\d+)$/i, method: :bet_lose
    match /bet\sdefeat\s(\d+)$/i, method: :bet_lose
    match /bet\slose\s(\d+)$/i,  # Betting on a loss
      method: (defn :bet_lose, ->(m, amount) { m.reply handle_user_bet(false, amount) })

    match /balance$/,
      method: (defn :balance, -> m { m.reply balance_for(m.user.name) })

    match /highscores$/,
      method: (defn :highscore, -> m { highscores.each { |h| m.reply h } })

  # COMMANDS FOR MODS: #
    match /bets\sopen$/i,    # Opening a round of betting
      method: (mods_only :bets_open, -> m { enable_betting(m) })

    match /bets\sclosed$/i,  # Closing the round of betting
      method: (mods_only :bets_closed, -> m { disable_betting(m) })

    match /won$/i,     # Recording the game outcome as a victory
      method: (mods_only :record_win, -> m { can_give_outcome?(m) && BetHandler.payout(m, true) })

    match /lost$/i,    # Recording the game outcome as a loss
      method: (mods_only :record_loss, -> m { can_give_outcome?(m) && BetHandler.payout(m, false) })

  private

  def highscores
    User.order(Sequel.desc(:coins)).take(5).each_with_index.map { |u, i| "#{i + 1}: #{u.name} (#{u.coins} jaggCoins)" }
  end

  def balance_for(name)
    user = User.get(name)
    "#{name}: You have #{user.coins} jaggCoins!"
  end

  def can_give_outcome?(m)
    if self.accept_bets
      m.reply "Betting is still open! Did you forget to close it?"
      false
    else
      true
    end
  end

  def enable_betting(m)
    if !self.accept_bets
      self.accept_bets = true
      m.reply "Betting is now OPEN!"
      m.reply 'If you think Jaggerous will win the next match, type "!bet win <amount>"'
      m.reply 'If you think Jaggerous will lose the next match, type "!bet lose <amount>"'
      BetHandler.start_new_round
    else
      m.reply "Betting is already open!"
    end
  end

  def disable_betting(m)
    if self.accept_bets
      self.accept_bets = false
      m.reply "Betting is now CLOSED!"
      BetHandler.summarise_round.each { |s| m.reply s }
    else
      m.reply "Betting is already closed!"
    end
  end

  def handle_user_bet(m, on_victory, amount)
    user = m.user.name
    if amount.to_i.zero?
      return "#{user}: Don't be afraid to dream a little bigger, darling."
    end
    if self.accept_bets
      result = BetHandler.handle_bet(user, on_victory, amount)
      if result.success
        return result.message
      else
        return "#{user}: #{result.message}"
      end

    else
      return "#{user}: Betting is currently closed!"
    end
  end

end
