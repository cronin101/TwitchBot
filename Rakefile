require_relative './database.rb'

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
