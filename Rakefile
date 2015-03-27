require_relative './database.rb'

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
end

namespace :db do

  task :create do
    puts 'Creating users table'
    User.create_table?

    puts 'Creating rounds table'
    Round.create_table?

    puts 'Creating bets table'
    Bet.create_table?

  end

  task :drop do
    puts 'Dropping db'
    DB.drop_table?(:bets, :rounds, :users)
  end

end
