require_relative './test_helper.rb'
require_relative '../gambling/bet_handler.rb'

# Stub HTTP call to Twitch API
def BetHandler.is_subscriber? u
  false
end

class BetHandlerTest < Minitest::Unit::TestCase

  def test_summariser
    temporarily do
      BetHandler.start_new_round

      a = User.get 'a', false
      b = User.get 'b', false

      no_bets = BetHandler.summarise_round

      BetHandler.start_new_round

      BetHandler.handle_bet(a.name, true, 1)
      for_victory = BetHandler.summarise_round

      BetHandler.start_new_round

      BetHandler.handle_bet(b.name, false, 1)
      for_loss = BetHandler.summarise_round

      BetHandler.start_new_round

      BetHandler.handle_bet(a.name, true, 1)
      BetHandler.handle_bet(b.name, false, 1)
      even_split = BetHandler.summarise_round

      responses = [no_bets, for_victory, for_loss, even_split]

      assert !responses.any?(&:nil?)
      assert_equal responses.length, responses.uniq.length
    end
  end

  def test_refunding
    temporarily do
      BetHandler.start_new_round

      better = User.get('better', false)

      assert_equal User::NON_SUB_COINS, better.coins

      BetHandler.handle_bet(better.name, true, better.coins / 2)

      better.reload
      assert_equal (User::NON_SUB_COINS / 2), better.coins

      BetHandler.reset_round

      better.reload
      assert_equal User::NON_SUB_COINS, better.coins
    end
  end

  def test_paying_out
    temporarily do
      correct = User.get 'correct', false
      correct_coins = correct.coins
      wrong   = User.get 'wrong', false
      wrong_coins = wrong.coins

      result = true

      BetHandler.start_new_round

      r = BetHandler.handle_bet(correct.name, result, correct_coins / 2)
      assert r.success

      r = BetHandler.handle_bet(wrong.name, !result, wrong_coins / 2)
      assert r.success

      BetHandler.payout(result)

      correct.reload
      wrong.reload
      assert_equal correct.coins, (correct_coins + (correct_coins / 2))
      assert_equal wrong.coins, wrong_coins / 2
    end
  end

  def test_rounds_for_and_against
    temporarily do
      BetHandler.start_new_round

      assert_equal 0, BetHandler.instance_eval { this_round.count }
      assert_equal 0, BetHandler.instance_eval { bets_for.count }
      assert_equal 0, BetHandler.instance_eval { bets_against.count }

      resp = BetHandler.handle_bet "optimist", true, 1
      assert resp.success

      assert_equal 1, BetHandler.instance_eval { this_round.count }
      assert_equal 1, BetHandler.instance_eval { bets_for.count }
      assert_equal 0, BetHandler.instance_eval { bets_against.count }

      resp = BetHandler.handle_bet "pessimist", false, 1
      assert resp.success

      assert_equal 2, BetHandler.instance_eval { this_round.count }
      assert_equal 1, BetHandler.instance_eval { bets_for.count }
      assert_equal 1, BetHandler.instance_eval { bets_against.count }

      BetHandler.start_new_round

      assert_equal 0, BetHandler.instance_eval { this_round.count }
      assert_equal 0, BetHandler.instance_eval { bets_for.count }
      assert_equal 0, BetHandler.instance_eval { bets_against.count }
    end
  end

  def test_handle_bet_only_allows_one_bet
    temporarily do
      BetHandler.start_new_round

      username = "username"
      user = User.get username, false

      # Placing a first bet should succeed
      response = BetHandler.handle_bet(username, true, user.coins / 2)
      assert response.success

      # Placing a second bet should fail
      response = BetHandler.handle_bet(username, true, user.coins / 2)
      assert !response.success
    end
  end

  def test_payout_can_only_occur_once
    temporarily do
      BetHandler.start_new_round

      username = 'Better'
      user = User.get username, false

      assert_equal User::NON_SUB_COINS, user.reload.coins

      result = true

      response = BetHandler.handle_bet(username, result, user.reload.coins / 2)

      assert_equal (User::NON_SUB_COINS / 2).to_i, user.reload.coins

      BetHandler.payout(result)

      assert_equal (User::NON_SUB_COINS * 1.5).to_i, user.reload.coins

      BetHandler.payout(result)

      assert_equal (User::NON_SUB_COINS * 1.5).to_i, user.reload.coins
    end
  end

  def test_initial_coins_varies_depending_on_whether_subscribed
    temporarily do
      assert_equal User::SUB_COINS, (User.get "subbed_user", true).coins
      assert_equal User::NON_SUB_COINS, (User.get "non_subbed_user", false).coins
    end
  end

  def test_handle_bet_only_allows_betting_within_budget
    temporarily do
      BetHandler.start_new_round

      valid_user = User.get "valid", false

      invalid_user = User.get "invalid", false

      # Placing a bet within budget should succeed
      remaining = 0
      valid_wager = valid_user.coins - remaining
      response = BetHandler.handle_bet(valid_user.name, true, valid_wager)
      assert response.success

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

end
