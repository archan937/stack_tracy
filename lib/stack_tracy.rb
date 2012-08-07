require "stack_tracy/event_info"
require "stack_tracy/version"

module StackTracy
  extend self

  def print(*only)
    call_stack, lines = [], []
    only = only.flatten
    stack_trace.each do |event_info|
      next unless process?(event_info, only)
      if event_info.call?
        lines << "#{"   " * call_stack.size}#{event_info.to_s}"
        call_stack << [lines.size - 1, event_info]
      elsif event_info.return? && call_stack.last && event_info.matches?(call_stack.last.last)
        call_stack.pop.tap do |(line, match)|
          lines[line] << " <#{"%.6f" % (event_info - match)}>"
        end
      end
    end
    puts lines
    nil
  end

private

  def process?(event_info, only)
    return true if only.empty?
    only.any?{|x| event_info.to_s.include? x}
  end

  def stack_trace
    @stack_trace || []
  end

  def store(stack_trace)
    @stack_trace = stack_trace
  end

end

require File.expand_path("../../ext/stack_tracy/stack_tracy", __FILE__)