require 'cinch'
require 'yaml'

require_relative 'gambling_plugin.rb'

# Twitch is special, deciding not to properly implement IRC.
# Therefore, we need to monkey-patch Cinch :-(
class Cinch::Message
  def reply(string)
    string = string.to_s.gsub('<','&lt;').gsub('>','&gt;')
    bot.irc.send ":#{bot.config.user}!#{bot.config.user}@#{bot.config.user}.tmi.twitch.tv PRIVMSG #{channel} :#{string}"
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.verbose         = true
    creds             = YAML.load_file('./auth.yaml')
    c.nick            = creds['username']
    c.password        = creds['oauth_token']
    c.server          = 'irc.twitch.tv'
    c.channels        = [creds['channel']]
    c.plugins.plugins = [GamblingPlugin]
  end

  on :message, "hello" do |m|
    m.reply "Hello #{m.user.nick}!"
  end
end

bot.start
