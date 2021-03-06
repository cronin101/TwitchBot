require_relative './test_helper.rb'
require_relative '../gambling/responder.rb'

class GamblingResponderTest < Minitest::Unit::TestCase
  GamblingResponder::Config = {}

  def test_get_explanation
    GamblingResponder.get_explanation { |e| assert e }
  end

  def test_get_highscores
    temporarily do
      Bet.all.map &:delete
      User.all.map &:delete
      GamblingResponder.get_highscores do |h|
        assert h
        assert_equal 0, h.count
      end

      User.get '1', -> { false }
      User.get '2', -> { false }
      User.get '3', -> { false }
      User.get '4', -> { false }
      User.get '5', -> { false }
      User.get '6', -> { false }

      GamblingResponder.get_highscores do |h|
        assert h
        assert_equal 5, h.count
      end
    end
  end

  def test_get_balance
    temporarily do
      name = "newly_created_user"
      GamblingResponder.get_balance(name) { |b| assert b }
    end
  end

  def test_enable_and_disable_betting
    temporarily do
      GamblingResponder.enable_betting { |m| assert m }
      assert GamblingResponder.class_eval { self.accept_bets }

      GamblingResponder.disable_betting { |m| assert m }
      assert GamblingResponder.class_eval { !self.accept_bets }
    end
  end

  def test_opening_bets_before_payout_does_not_reset
    temporarily do
      # Bets opened
      GamblingResponder.enable_betting { |m| assert m }
      assert GamblingResponder.class_eval { self.accept_bets }

      # Bet placed
      GamblingResponder.place_bet("username", true, 10) { |m| assert m }

      # Bets closed
      GamblingResponder.disable_betting { |m| assert m }
      assert GamblingResponder.class_eval { !self.accept_bets }

      # Bets (accidentally attempted to be) re-opened
      GamblingResponder.enable_betting { |m| assert m }

      # The bets should remain closed
      assert GamblingResponder.class_eval { !self.accept_bets }

      # All placed bets should remain in the current round
      assert (GamblingResponder.instance_eval { BetHandler.instance_eval { this_round.count }} == 1)

      # Once payout has occurred...
      GamblingResponder.record_outcome(true){ |m| assert m }

      # ...it should be possible to open the bets again
      GamblingResponder.enable_betting { |m| assert m }
      assert GamblingResponder.class_eval { self.accept_bets }
    end
  end

  def test_place_bet
    temporarily do
      GamblingResponder.place_bet("username", true, 10) { |m| assert m }
    end
  end

end
