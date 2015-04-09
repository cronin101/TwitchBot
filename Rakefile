require_relative './gambling/database.rb'

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
end

namespace :db do

  task :add_daily_coins do
    added_coins = 10

    eligible = User.join_table(
        # Users with associated bets...
        :inner,
        # ...Placed within the last 24h, limiting one per user
        Bet.last_24h.select(:user_id).distinct,
        # Joining on the Foreign Key
        user_id: :id)

    eligible.each { |u| u.reload and u.coins += added_coins and u.save }
  end

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
