require_relative '../rubby_module.rb'
require_relative './responder.rb'
require_relative './bet_handler.rb'

def op?(message)
  sender = message.user.name
  message.channel.opped?(sender)
end

class GamblingPlugin
  include Cinch::Plugin
  extend Rubby

  Responder = GamblingResponder

  # Decorator to make commands fire only if triggered by a moderator
  def self.mod_command method_name
    method_name.tap do |name|
      body = instance_method name
      define_method name do |*args, &block|
        body.bind(self).call(*args, &block) if op?(args.first)
      end
    end
  end

  def self.mods_only name, block
    mod_command defn name, block
  end

  # Sugar for interacting with IRC:
    # Given a message, returns a function that will reply using an array of response lines
    Replier = -> m { -> ls { ls.each { |l| m.reply l } } }

    # Given a message, returns the username of the author
    Nameof  = -> m { m.user.name }

  # COMMANDS FOR EVERYONE: #
    # A user can ask for an explanation of the betting system
    match /jaggcoins$/i,
      method: (throttle 60, (defn :explanation,
               -> m { Responder.get_explanation &Replier.(m) }))

    # A user can place a bet on victory
    match /bet\s(?:win|victory)\s(\d+)$/i,
      method: (defn :bet_win,
               ->(m, amount) { Responder.place_bet(Nameof.(m), true, amount, &Replier.(m)) })

    # A user can place a bet on defeat
    match /bet\s(?:lose|loss|defeat)\s(\d+)$/i,
      method: (defn :bet_lose,
               ->(m, amount) { Responder.place_bet(Nameof.(m), false, amount, &Replier.(m)) })

    # A user can display their balance
    match /balance$/,
      method: (defn :balance,
               -> m { Responder.get_balance(Nameof.(m), &Replier.(m)) })

    # A user can display the highscores
    match /highscores$/,
      method: (throttle 60, (defn :highscore,
               -> m { Responder.get_highscores(&Replier.(m)) }))

  # COMMANDS FOR MODS: #
    # A mod can open a round of betting
    match /bets\sopen$/i,
      method: (mods_only :bets_open,
               -> m { Responder.enable_betting(&Replier.(m)) })

    # A mod can close the round of betting
    match /bets\sclosed$/i,
      method: (mods_only :bets_closed,
               -> m { Responder.disable_betting(&Replier.(m)) })

    # A mod can record the game outcome as a victory
    match /won$/i,
      method: (mods_only :record_win,
               -> m { Responder.record_outcome(true, &Replier.(m)) })

    # A mod can record the game outcome as a loss
    match /lost$/i,
      method: (mods_only :record_loss,
               -> m { Responder.record_outcome(false, &Replier.(m)) })

end
