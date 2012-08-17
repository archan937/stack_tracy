#
# This benchmark is compared with ruby-prof:
#
#   require 'ruby-prof'
#   require 'benchmark'
#
#   $stdout.sync = true
#
#   puts Benchmark.realtime {
#     100000.times { print ""  }
#   }
#
#   puts Benchmark.realtime {
#     RubyProf.profile do
#       100000.times { print ""  }
#     end
#   }
#
#   for n in [5, 100] do
#     n.times { Thread.new { sleep }}
#     puts Benchmark.realtime {
#       RubyProf.profile do
#         100000.times { print ""  }
#       end
#     }
#   end
#
# $ ruby ruby-prof/benchmarks/benchmark.rb
#   0.061315
#   1.201144
#   1.404983
#   6.558329

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "benchmark"
require "stack_tracy"

$stdout.sync = true

puts Benchmark.realtime {
  100000.times { print ""  }
}

puts Benchmark.realtime {
  stack_tracy do
    100000.times { print ""  }
  end
}

for n in [5, 100] do
  n.times { Thread.new { sleep }}
  puts Benchmark.realtime {
    stack_tracy do
      100000.times { print ""  }
    end
  }
end

# $ ruby stack_tracy/benchmarks/benchmark.rb
#   0.035907
#   2.096276
#   2.575487
#   4.770742
