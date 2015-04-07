require 'sequel'
require 'sqlite3'

DB = Sequel.sqlite( __dir__ + '/jaggerous.db')

class User < Sequel::Model(:users)
  SUB_COINS     = 200
  NON_SUB_COINS = 100

  def self.create_table?
    DB.create_table? :users do
      primary_key :id
      String :name, null: false
      Integer :coins, null: false
    end
  end

  def self.get(name, is_sub_check)
    User.find_or_create(name: name) { |u| u.coins =  is_sub_check.() ? SUB_COINS : NON_SUB_COINS }
  end
end

class Round < Sequel::Model(:rounds)
  def self.create_table?
    DB.create_table? :rounds do
      primary_key :number
    end
  end
end

class Bet < Sequel::Model(:bets)
  def self.create_table?
    DB.create_table? :bets do
      primary_key :id
      foreign_key :round, :rounds, null: false
      foreign_key :user_id, :users, null: false
      Integer :amount, null: false
      TrueClass :is_on_victory, null: false
    end
  end
end

