require "erb"
require "csv"
require "rich/support/core/string/colorize"
require "launchy"

require "stack_tracy/core_ext"
require "stack_tracy/event_info"
require "stack_tracy/version"

module StackTracy
  extend self

  class Error < StandardError; end

  def start(options = {})
    # options[:exclude] ||= "Array BasicObject Enumerable Fixnum Float Hash IO Kernel Module Mutex Numeric Object Rational String Symbol Thread Time"
    _start [options[:only] || []].flatten.join(" "), [options[:exclude] || []].flatten.join(" ")
    nil
  end

  def stop
    _stop
    nil
  end

  def stack_trace
    @stack_trace || []
  end

  def select(*only)
    [].tap do |lines|
      first, call_stack, only = nil, [], only.flatten.collect{|x| x.split(" ")}.flatten
      stack_trace.each do |event_info|
        next unless process?(event_info, only)
        first ||= event_info
        if event_info.call?
          lines << event_info.to_hash(first).merge!(:depth => call_stack.size)
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
    keys = [:event, :file, :line, :singleton, :object, :method, :nsec, :time, :call, :depth, :duration]
    File.open(File.expand_path(path), "w") do |file|
      file << keys.join(";") + "\n"
      select(only).each do |event|
        file << event.values_at(*keys).join(";") + "\n"
      end
    end
    true
  end

  def open(path = nil)
    if File.exists?(file = File.expand_path(path || "."))
      file = (File.extname(file) == ".csv") ? file : File.join(file, "stack_events.csv")
    end
    if File.exists? file
      events = StackTracy::EventInfo.to_hashes File.read(file)
      erb = ERB.new File.new(ui("index.html.erb")).read
      index = ui("index.html")
      File.open(index, "w"){|f| f.write erb.result(binding)}
      Launchy.open("file://#{index}")
      nil
    else
      raise Error, "Could not locate StackTracy file"
    end
  end

private

  def process?(event_info, only)
    return true if only.empty?
    only.any?{|x| event_info.matches?(x)}
  end

  def ui(file)
    File.expand_path("../../ui/#{file}", __FILE__)
  end

end

require File.expand_path("../../ext/stack_tracy/stack_tracy", __FILE__)