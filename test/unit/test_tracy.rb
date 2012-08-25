require File.expand_path("../../test_helper", __FILE__)

module Unit
  class TestTracy < MiniTest::Unit::TestCase

    describe StackTracy do
      after do
        StackTracy.config do |c|
          c.only = nil
          c.exclude = nil
        end
      end

      it "should respond to methods as expected" do
        assert StackTracy.respond_to?(:config)
        assert StackTracy.respond_to?(:start)
        assert StackTracy.respond_to?(:stop)
        assert StackTracy.respond_to?(:stack_trace)
        assert StackTracy.respond_to?(:select)
        assert StackTracy.respond_to?(:print)
        assert StackTracy.respond_to?(:dump)
        assert StackTracy.respond_to?(:open)
      end

      it "should be configurable" do
        StackTracy.config do |c|
          assert_equal true, c.is_a?(Struct)
          assert_equal [:dump_dir, :only, :exclude], c.members
          c.only = "Kernel"
          c.exclude = ["IO", "String"]
        end

        assert_equal({:only => "Kernel", :exclude => ["IO", "String"]}, StackTracy.send(:merge_options))
        assert_equal({:only => "Object", :exclude => ["IO", "String"]}, StackTracy.send(:merge_options, {:only => "Object"}))
        assert_equal({:only => "Object", :exclude => nil}, StackTracy.send(:merge_options, {:only => "Object", :exclude => nil}))
        assert_equal({:only => "Paul", :exclude => "Foo"}, StackTracy.send(:merge_options, {"only" => "Paul", "exclude" => "Foo"}))
        assert_equal({:only => nil, :exclude => nil}, StackTracy.send(:merge_options, {:only => nil, :exclude => nil}))

        assert_equal(
          "Array BasicObject Enumerable Fixnum Float Foo Hash IO Integer Kernel Module Mutex Numeric Object Rational String Symbol Thread Time",
          StackTracy.send(:mod_names, [:core, "Foo"])
        )

        assert_equal(
          "ActiveRecord::Base",
          StackTracy.send(:mod_names, :active_record)
        )

        assert_equal(
          "DataMapper::Resource",
          StackTracy.send(:mod_names, :data_mapper)
        )
      end

      it "should have the expected stack trace" do
        stack_tracy do
          puts "testing"
        end
        file, line = __FILE__, __LINE__ - 2
        st = File.expand_path("../../../lib/stack_tracy.rb", __FILE__)

        assert_equal [
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => Kernel    , :method => "puts" , :call => "Kernel#puts"     },
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => IO        , :method => "puts" , :call => "IO#puts"         },
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => IO        , :method => "write", :call => "IO#write"        },
          {:event => "c-return", :file => file, :line => line, :singleton => false, :object => IO        , :method => "write", :call => "IO#write"        },
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => IO        , :method => "write", :call => "IO#write"        },
          {:event => "c-return", :file => file, :line => line, :singleton => false, :object => IO        , :method => "write", :call => "IO#write"        },
          {:event => "c-return", :file => file, :line => line, :singleton => false, :object => IO        , :method => "puts" , :call => "IO#puts"         },
          {:event => "c-return", :file => file, :line => line, :singleton => false, :object => Kernel    , :method => "puts" , :call => "Kernel#puts"     },
          {:event => "call"    , :file => st  , :line => 35  , :singleton => false, :object => StackTracy, :method => "stop" , :call => "StackTracy#stop" },
          {:event => "c-call"  , :file => st  , :line => 36  , :singleton => 0    , :object => StackTracy, :method => "_stop", :call => "StackTracy._stop"}
        ], StackTracy.stack_trace.collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            hash.delete(:time)
          end
        }

        assert_equal true, StackTracy.stack_trace.first.call?
        assert_equal false, StackTracy.stack_trace.first.return?

        StackTracy.config do |c|
          c.exclude = ["IO"]
        end
        stack_tracy do
          puts "testing"
        end
        file, line = __FILE__, __LINE__ - 2

        assert_equal [
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => Kernel    , :method => "puts" , :call => "Kernel#puts"     },
          {:event => "c-return", :file => file, :line => line, :singleton => false, :object => Kernel    , :method => "puts" , :call => "Kernel#puts"     },
          {:event => "call"    , :file => st  , :line => 35  , :singleton => false, :object => StackTracy, :method => "stop" , :call => "StackTracy#stop" },
          {:event => "c-call"  , :file => st  , :line => 36  , :singleton => 0    , :object => StackTracy, :method => "_stop", :call => "StackTracy._stop"}
        ], StackTracy.stack_trace.collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            hash.delete(:time)
          end
        }

        StackTracy.config do |c|
          c.exclude = :core
        end
        stack_tracy do
          puts "testing"
        end

        assert_equal 2, StackTracy.stack_trace.size
      end

      it "should return a printable version of the stack trace" do
        stack_tracy do
          puts "testing"
        end
        file, line = __FILE__, __LINE__ - 2

        assert_equal [
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => Kernel, :method => "puts" , :call => "Kernel#puts", :depth => 0},
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => IO    , :method => "puts" , :call => "IO#puts"    , :depth => 1},
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => IO    , :method => "write", :call => "IO#write"   , :depth => 2},
          {:event => "c-call"  , :file => file, :line => line, :singleton => false, :object => IO    , :method => "write", :call => "IO#write"   , :depth => 2}
        ], StackTracy.select.collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
            hash.delete(:time)
          end
        }
      end

      it "should clear StackTracy.stack_trace after having invoked StackTracy.dump" do
        stack_tracy do
          puts "testing"
        end
        assert_equal false, StackTracy.stack_trace.empty?

        StackTracy.dump
        assert_equal true, StackTracy.stack_trace.empty?

        stack_tracy do
          puts "testing"
        end
        assert_equal false, StackTracy.stack_trace.empty?

        StackTracy.expects(:foo)
        StackTracy.dump do |file|
          assert file.match(/\/.*\.csv/)
          assert_equal false, StackTracy.stack_trace.empty?
          StackTracy.foo
        end

        assert_equal true, StackTracy.stack_trace.empty?
      end

      it "should filter methods as expected" do
        stack_tracy do
          puts "testing"
        end
        file, line = __FILE__, __LINE__ - 2

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => Kernel, :method => "puts" , :call => "Kernel#puts", :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO    , :method => "puts" , :call => "IO#puts"    , :depth => 1},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO    , :method => "write", :call => "IO#write"   , :depth => 2},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO    , :method => "write", :call => "IO#write"   , :depth => 2}
        ], StackTracy.select("*").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
            hash.delete(:time)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => Kernel, :method => "puts", :call => "Kernel#puts", :depth => 0}
        ], StackTracy.select("Kernel").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
            hash.delete(:time)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "puts" , :call => "IO#puts" , :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "write", :call => "IO#write", :depth => 1},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "write", :call => "IO#write", :depth => 1}
        ], StackTracy.select("IO").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
            hash.delete(:time)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "puts" , :call => "IO#puts" , :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "write", :call => "IO#write", :depth => 1},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "write", :call => "IO#write", :depth => 1}
        ], StackTracy.select("IO*").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
            hash.delete(:time)
          end
        }

        assert_equal [
        ], StackTracy.select("I*").collect{ |event_info|
          event_info.to_hash
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "puts" , :call => "IO#puts" , :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "write", :call => "IO#write", :depth => 1},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "write", :call => "IO#write", :depth => 1}
        ], StackTracy.select("IO#").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
            hash.delete(:time)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "write", :call => "IO#write", :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "write", :call => "IO#write", :depth => 0}
        ], StackTracy.select("IO#w*").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
            hash.delete(:time)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "write", :call => "IO#write", :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO, :method => "write", :call => "IO#write", :depth => 0}
        ], StackTracy.select("IO#write").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
            hash.delete(:time)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => Kernel, :method => "puts", :call => "Kernel#puts", :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO    , :method => "puts", :call => "IO#puts"    , :depth => 1}
        ], StackTracy.select("*#puts").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
            hash.delete(:time)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => Kernel, :method => "puts" , :call => "Kernel#puts", :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO    , :method => "write", :call => "IO#write"   , :depth => 1},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO    , :method => "write", :call => "IO#write"   , :depth => 1}
        ], StackTracy.select(%w(Kernel #write)).collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
            hash.delete(:time)
          end
        }

        assert_equal [
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => Kernel, :method => "puts" , :call => "Kernel#puts", :depth => 0},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO    , :method => "write", :call => "IO#write"   , :depth => 1},
          {:event => "c-call", :file => file, :line => line, :singleton => false, :object => IO    , :method => "write", :call => "IO#write"   , :depth => 1}
        ], StackTracy.select("Kernel IO#write").collect{ |event_info|
          event_info.to_hash.tap do |hash|
            assert hash.delete(:nsec)
            assert hash.delete(:duration)
            hash.delete(:time)
          end
        }
      end
    end

  end
end