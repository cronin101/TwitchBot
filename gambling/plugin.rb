require_relative '../rubby_module.rb'
require_relative './responder.rb'
require_relative './bet_handler.rb'

class GamblingPlugin
  include Cinch::Plugin
  extend Rubby

  Responder = GamblingResponder

  def self.op?(message)
    sender = message.user.name
    message.channel.opped?(sender)
  end

  # Decorator to make commands fire only if triggered by a moderator
  def self.mod_command method_name
    method_name.tap do |name|
      body = instance_method name
      define_method name do |*args, &block|
        body.bind(self).call(*args, &block) if GamblingPlugin.op?(args.first)
      end
    end
  end

  # COMMANDS FOR EVERYONE: #
    # A user can ask for an explanation of the betting system
    match /jaggcoins$/i, method: (throttle 60, def explanation msg
      Responder.get_explanation &(response_stream msg)
    end)

    # A user can place a bet on victory
    match /bet\s(?:win|victory)\s(\d+)$/i, method: (def bet_win msg, amount
      Responder.place_bet(msg.user.name, true, amount, &(response_stream msg))
    end)

    # A user can place a bet on defeat
    match /bet\s(?:lose|loss|defeat)\s(\d+)$/i, method: (def bet_lose msg, amount
      Responder.place_bet(msg.user.name, false, amount, &(response_stream msg))
    end)

    # A user can display their balance
    match /balance$/, method: (def balance msg
      Responder.get_balance(msg.user.name, &(response_stream msg))
    end)

    # A user can display the highscores
    match /highscores$/, method: (throttle 60, def highscores msg
      Responder.get_highscores &(response_stream msg)
    end)

  # COMMANDS FOR MODS: #
    # A mod can open a round of betting
    match /bets\sopen$/i, method: (mod_command def bets_open msg
      Responder.enable_betting &(response_stream msg)
    end)

    # A mod can close the round of betting
    match /bets\s(?:closed|close)$/i, method: (mod_command def bets_closed msg
      Responder.disable_betting &(response_stream msg)
    end)

    # A mod can reset the round of betting
    match /reset$/i, method: (mod_command def reset msg
      Responder.reset_round &(response_stream msg)
    end)

    # A mod can record the game outcome as a victory
    match /won$/i, method: (mod_command def record_win msg
      Responder.record_outcome(true, &(response_stream msg))
    end)

    # A mod can record the game outcome as a loss
    match /lost$/i, method: (mod_command def record_loss msg
      Responder.record_outcome(false, &(response_stream msg))
    end)

    private

    def response_stream msg
      -> response { response.each { |l| msg.reply l } }
    end

end
