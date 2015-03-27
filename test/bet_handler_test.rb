require 'minitest/autorun'
require_relative '../bet_handler.rb'

class BetHandlerTest < Minitest::Unit::TestCase
  # In-Memory Table
  DB = Sequel.sqlite

  Response = Struct.new(:success, :message)
  def test_handle_bet_only_allows_one_bet
    with_clean_db do
      BetHandler.start_new_round

      username = "username"
      user = User.get username

      # Placing a first bet should succeed
      response = BetHandler.handle_bet(username, true, user.coins / 2)
      assert response.success

      # Placing a second bet should fail
      response = BetHandler.handle_bet(username, true, user.coins / 2)
      assert !response.success
    end
  end

  def test_handle_bet_only_allows_betting_within_budget
    with_clean_db do
      BetHandler.start_new_round

      valid_user = User.get "valid"

      invalid_user = User.get "invalid"

      # Placing a bet within budget should succeed
      remaining = 0
      valid_wager = valid_user.coins - remaining
      response = BetHandler.handle_bet(valid_user.name, true, valid_wager)
      assert response.success, response.message

      # The valid person should now have lighter pockets
      valid_user.reload
      assert_equal remaining, valid_user.coins

      # Placing a bet beyond budget should fail
      invalid_user_total = invalid_user.coins
      invalid_wager = invalid_user.coins + 1
      response = BetHandler.handle_bet(invalid_user.name, true, invalid_wager)
      assert !response.success

      # The invalid person should have lost nothing
      invalid_user.reload
      assert_equal invalid_user_total, invalid_user.coins
    end
  end

  private

  def with_clean_db(&block)
    User.create_table?
    Round.create_table?
    Bet.create_table?

    block.call

    DB.drop_table?(:bets, :rounds, :users)
  end

end
