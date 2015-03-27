require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'minitest/autorun'

def temporarily(&block)
  Sequel::Model.db.transaction(:rollback => :always, :auto_savepoint=>true) do
    block.call
  end
end


