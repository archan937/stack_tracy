require File.expand_path("../../test_helper", __FILE__)

module Unit
  class TestTracy < MiniTest::Unit::TestCase

    describe StackTracy do
      it "should respond to methods as expected" do
        assert StackTracy.respond_to?(:start)
        assert StackTracy.respond_to?(:stop)
        assert StackTracy.respond_to?(:stack_trace)
        assert StackTracy.respond_to?(:select)
        assert StackTracy.respond_to?(:print)
      end

      it "should have the expected stack trace" do
        stack_tracy do
          puts "testing"
        end
        file, line = __FILE__, __LINE__ - 2

        assert_equal [
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => "Kernel", :method => "puts" , :call => "Kernel#puts"},
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "puts" , :call => "IO#puts"    },
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "write", :call => "IO#write"   },
          {:event => "c-return", :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "write", :call => "IO#write"   },
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "write", :call => "IO#write"   },
          {:event => "c-return", :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "write", :call => "IO#write"   },
          {:event => "c-return", :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "puts" , :call => "IO#puts"    },
          {:event => "c-return", :file => file, :line => line, :singleton => false, :object => "Kernel", :method => "puts" , :call => "Kernel#puts"}
        ], StackTracy.stack_trace.collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
          end
        }

        assert StackTracy.stack_trace.first.call?
        assert !StackTracy.stack_trace.last.call?

        assert !StackTracy.stack_trace.first.return?
        assert StackTracy.stack_trace.last.return?
      end

      it "should return a printable version of the stack trace" do
        stack_tracy do
          puts "testing"
        end
        file, line = __FILE__, __LINE__ - 2

        assert_equal [
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => "Kernel", :method => "puts" , :call => "Kernel#puts", :depth => 0},
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "puts" , :call => "IO#puts"    , :depth => 1},
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "write", :call => "IO#write"   , :depth => 2},
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "write", :call => "IO#write"   , :depth => 2}
        ], StackTracy.select.collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
          end
        }
      end

      it "should filter methods as expected" do
        stack_tracy do
          puts "testing"
        end
        file, line = __FILE__, __LINE__ - 2

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "Kernel", :method => "puts" , :call => "Kernel#puts", :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "puts" , :call => "IO#puts"    , :depth => 1},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "write", :call => "IO#write"   , :depth => 2},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "write", :call => "IO#write"   , :depth => 2}
        ], StackTracy.select("*").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "Kernel", :method => "puts", :call => "Kernel#puts", :depth => 0}
        ], StackTracy.select("Kernel").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO", :method => "puts" , :call => "IO#puts" , :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO", :method => "write", :call => "IO#write", :depth => 1},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO", :method => "write", :call => "IO#write", :depth => 1}
        ], StackTracy.select("IO").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO", :method => "puts" , :call => "IO#puts" , :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO", :method => "write", :call => "IO#write", :depth => 1},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO", :method => "write", :call => "IO#write", :depth => 1}
        ], StackTracy.select("IO#").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO", :method => "write", :call => "IO#write", :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO", :method => "write", :call => "IO#write", :depth => 0}
        ], StackTracy.select("IO#w*").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO", :method => "write", :call => "IO#write", :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO", :method => "write", :call => "IO#write", :depth => 0}
        ], StackTracy.select("IO#write").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "Kernel", :method => "puts", :call => "Kernel#puts", :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "puts", :call => "IO#puts"    , :depth => 1}
        ], StackTracy.select("*#puts").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "Kernel", :method => "puts" , :call => "Kernel#puts", :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "write", :call => "IO#write"   , :depth => 1},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => "IO"    , :method => "write", :call => "IO#write"   , :depth => 1}
        ], StackTracy.select(%w(Kernel #write)).collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
          end
        }
      end
    end

  end
end