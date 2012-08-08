require File.expand_path("../../test_helper", __FILE__)

module Unit
  class TestKernel < MiniTest::Unit::TestCase

    describe Kernel do
      it "should respond to stack_tracy and behave as expected" do
        assert Kernel.respond_to?(:stack_tracy)
      end
    end

  end
end