require "erb"
require "csv"
require "tmpdir"
require "securerandom"
require "rich/support/core/string/colorize"
require "launchy"

require "stack_tracy/core_ext"
require "stack_tracy/event_info"
require "stack_tracy/sinatra"
require "stack_tracy/version"

module StackTracy
  extend self

  PRESETS = {
    :core => "Array BasicObject Enumerable Fixnum Float Hash IO Integer Kernel Module Mutex Numeric Object Rational String Symbol Thread Time",
    :active_record => "ActiveRecord::Base",
    :data_mapper => "DataMapper::Resource"
  }
  @options = Struct.new(:dump_dir, :only, :exclude).new(Dir::tmpdir)

  class Error < StandardError; end

  def config
    yield @options
  end

  def start(options = {})
    opts = merge_options(options)
    _start mod_names(opts[:only]), mod_names(opts[:exclude])
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

  def dump(path = nil, *only)
    unless path && path.match(/\.csv$/)
      path = File.join [path || @options.dump_dir, "stack_events-#{SecureRandom.hex(3)}.csv"].compact
    end
    File.expand_path(path).tap do |path|
      keys = [:event, :file, :line, :singleton, :object, :method, :nsec, :time, :call, :depth, :duration]
      File.open(path, "w") do |file|
        file << keys.join(";") + "\n"
        select(only).each do |event|
          file << event.values_at(*keys).join(";") + "\n"
        end
      end
    end
  end

  def open(path = nil, use_current_stack_trace = false)
    unless use_current_stack_trace
      unless path && path.match(/\.csv$/)
        path = Dir[File.join(path || @options.dump_dir, "stack_events-*.csv")].sort_by{|f| File.mtime(f)}.last
        path ||= Dir[File.join(path || Dir::tmpdir, "stack_events-*.csv")].sort_by{|f| File.mtime(f)}.last
      end
      if path
        file = File.expand_path(path)
      else
        raise Error, "Could not locate StackTracy file"
      end
    end

    index = ui("index.html")

    if use_current_stack_trace || (file && File.exists?(file))
      events = use_current_stack_trace ? select : StackTracy::EventInfo.to_hashes(File.read(file))
      erb = ERB.new File.new(ui("index.html.erb")).read
      File.open(index, "w"){|f| f.write erb.result(binding)}
    elsif path && path.match(/\.csv$/)
      raise Error, "Could not locate StackTracy file at #{file}"
    end

    if File.exists?(index)
      Launchy.open("file://#{index}")
      nil
    else
      raise Error, "Could not locate StackTracy file"
    end
  end

private

  def merge_options(hash = {})
    {:only => @options.only, :exclude => @options.exclude}.merge(hash.inject({}){|h, (k, v)| h.merge!(k.to_sym => v)})
  end

  def mod_names(arg)
    names = PRESETS.inject([arg || []].flatten.collect(&:to_s).join(" ")){|s, (k, v)| s.gsub k.to_s, v}
    if names.include?("*")
      names.split(/\s/).collect do |name|
        name.include?("*") ? mods_within([constantize(name.gsub("*", ""))]).collect(&:name) : spec
      end.flatten
    else
      names.split(/\s/)
    end.sort.join(" ")
  end

  def constantize(name)
    name.split("::").inject(Kernel){|m, x| m.const_get x}
  end

  def mods_within(mods, initial_array = nil)
    (initial_array || mods).tap do |array|
      mods.each do |mod|
        mod.constants.each do |c|
          const = mod.const_get c
          if !array.include?(const) && (const.is_a?(Class) || const.is_a?(Module)) && const.name.match(/^#{mod.name}/)
            array << const
            mods_within([const], array)
          end
        end
      end
    end
  end

  def process?(event_info, only)
    return true if only.empty?
    only.any?{|x| event_info.matches?(x)}
  end

  def ui(file)
    File.expand_path("../../ui/#{file}", __FILE__)
  end

end

require File.expand_path("../../ext/stack_tracy/stack_tracy", __FILE__)