require 'yaml'
require_relative './rubby_module.rb'

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

  Config = YAML.load_file('./jaggcoins_config.yaml')

  match /jaggcoins$/,     # Explanation of the betting system
  method: (defn :explanation, ->(m) { m.reply Config['explanation'] })

  match /bets\sopen$/,    # Opening a round of betting
  method: (mod_command defn :bets_open, -> m { enable_betting })

  match /bets\sclosed$/,  # Closing the round of betting
  method: (mod_command defn :bets_closed, -> m { disable_betting })

  match /game\swin$/,     # Recording the game outcome as a victory
  method: (mod_command defn :record_win, -> m { Scoreboard.add_win })

  match /game\slose$/,    # Recording the game outcome as a loss
  method: (mod_command defn :record_loss, -> m { Scoreboard.add_loss })

  private

  defn :enable_betting, -> { accept_bets = true }
  defn :disable_betting, -> { accept_bets = false }

end
