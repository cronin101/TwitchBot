require 'cinch'
require 'cinch/test'

require_relative './test_helper.rb'
require_relative "../rubby_module.rb"
require_relative '../gambling/plugin.rb'

# Stub the GamblingResponder to avoid side-effects
class GamblingPluginTest < Minitest::Unit::TestCase
  include Cinch::Test

  USER_COMMANDS = [
                    "!jaggcoins", "!bet win 1", "!bet victory 1", "!bet lose 1",
                    "!bet loss 1", "!bet defeat 1", "!balance", "!highscores",
                  ]

  MOD_COMMANDS =  [
                    "!won", "!lost", "!bets open", "!bets closed", "!bets close", "!reset"
                  ]

  module NewResponder
    def self.method_missing(method, *args, &block)
      yield [(GamblingResponder.respond_to? method)]
    end
  end

  GamblingPlugin::Responder = NewResponder

  def test_commands_for_user
    without_throttling do
      def GamblingPlugin.op?(*args)
        false
      end

      # The bot should respond to user commands
      USER_COMMANDS.each do |com|
        temporarily do
          bot = make_bot(GamblingPlugin)
          assert (bot.is_a? Cinch::Bot)
          message = make_message(bot, com)
          replies = get_replies(message)
          assert replies.length > 0, "Responds to #{com} from user"
          replies.each { |reply| assert_equal true, reply.text }
        end
      end

      # The bot shouldn't respond to mod commands
      MOD_COMMANDS.each do |com|
        temporarily do
          bot = make_bot(GamblingPlugin)
          assert (bot.is_a? Cinch::Bot)
          message = make_message(bot, com)
          replies = get_replies(message)
          assert replies.length == 0, "Doesn't repond to #{com} from user"
        end
      end
    end
  end

  def test_commands_for_mod
    without_throttling do
      def GamblingPlugin.op?(*args)
        true
      end

      # The bot should respond to all commands
      (USER_COMMANDS + MOD_COMMANDS).each do |com|
        temporarily do
          bot = make_bot(GamblingPlugin)
          assert (bot.is_a? Cinch::Bot)
          message = make_message(bot, com)
          replies = get_replies(message)
          assert replies.length > 0, "Responds to #{com} from mod"
          replies.each { |reply| assert_equal true, reply.text }
        end
      end
    end
  end
end
