require File.expand_path("../../test_helper", __FILE__)

module Unit
  class TestString < MiniTest::Unit::TestCase

    describe String do
      it "should respond to tracy" do
        assert "".respond_to?(:tracy)
      end
    end

  end
end