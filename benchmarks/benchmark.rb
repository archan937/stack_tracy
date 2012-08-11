$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "benchmark"
require "stack_tracy"

def go
end

puts Benchmark.realtime {
  100000.times { go }
}

puts Benchmark.realtime {
  stack_tracy do
    100000.times { go }
  end
}

for n in [5, 100] do
  n.times { Thread.new { sleep }}
  puts Benchmark.realtime {
    stack_tracy do
      100000.times { go }
    end
  }
end