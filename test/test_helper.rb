require 'codeclimate-test-reporter'

require_relative '../logging.rb'

Log.remove_appenders Logfile

CodeClimate::TestReporter.start

require 'minitest/autorun'

def temporarily(&block)
  Sequel::Model.db.transaction(:rollback => :always, :auto_savepoint=>true) do
    block.call
  end
end

def without_throttling(&block)
  Rubby::THROTTLING[:active] = false
  block.call
ensure
  Rubby::THROTTLING[:active] = true
end

