require "stack_tracy/core_ext"
require "stack_tracy/event_info"
require "stack_tracy/version"

module StackTracy
  extend self

  def stack_trace
    @stack_trace || []
  end

  def select(*only)
    [].tap do |lines|
      call_stack, only = [], only.flatten.collect{|x| x.split(" ")}.flatten
      stack_trace.each do |event_info|
        next unless process?(event_info, only)
        if event_info.call?
          lines << event_info.to_hash.merge!(:depth => call_stack.size)
          call_stack << [lines.size - 1, event_info]
        elsif event_info.return? && call_stack.last && event_info.matches?(call_stack.last.last)
          call_stack.pop.tap do |(line, match)|
            lines[line][:duration] = event_info - match
          end
        end
      end
    end
  end

  def print(*only)
    puts select(only).collect{ |event|
      line = "   " * event[:depth]
      line << event[:call]
      line << " <#{"%.6f" % event[:duration]}>" if event[:duration]
    }
  end

  def dump(path, *only)
    keys = [:event, :file, :line, :singleton, :object, :method, :nsec, :call, :depth, :duration]
    File.open(File.expand_path(path), "w") do |file|
      file << keys.join(";") + "\n"
      select(only).each do |event|
        file << event.values_at(*keys).join(";") + "\n"
      end
    end
    true
  end

private

  def store(stack_trace)
    @stack_trace = stack_trace
  end

  def process?(event_info, only)
    return true if only.empty?
    only.any?{|x| event_info.matches?(x)}
  end

end

require File.expand_path("../../ext/stack_tracy/stack_tracy", __FILE__)