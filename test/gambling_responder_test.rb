require_relative './test_helper.rb'
require_relative '../gambling/responder.rb'

class GamblingResponderTest < Minitest::Unit::TestCase
  GamblingResponder::Config = {}
  GamblingResponder::Config['mods'] = ['mod']
  GamblingResponder::Config['explanation'] = "explanation"

  def test_is_mod
    assert GamblingResponder.is_mod? 'mod'
    assert !(GamblingResponder.is_mod? 'non-mod')
  end

  def test_get_explanation
    GamblingResponder.get_explanation { |e| assert e }
  end

  def test_get_highscores
    temporarily do
      User.all.map &:delete
      GamblingResponder.get_highscores do |h|
        assert h
        assert_equal 0, h.count
      end

      User.get '1', false
      User.get '2', false
      User.get '3', false
      User.get '4', false
      User.get '5', false
      User.get '6', false

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

  def test_place_bet
    temporarily do
      GamblingResponder.place_bet("username", true, 10) { |m| assert m }
    end
  end

end
