require "thor"
require "stack_tracy"

module StackTracy
  class CLI < Thor

    default_task :open

    desc "open [PATH]", "Display StackTracy data within the browser (PATH is optional)"
    method_options [:limit, "-l"] => :numeric, [:threshold, "-t"] => :numeric, [:messages_only, "-m"] => :false, [:slows_only, "-s"] => :false
    def open(path = ".")
      StackTracy.open path, false, options
    end

  private

    def method_missing(method, *args)
      if File.exists? File.expand_path(method.to_s)
        `tracy open #{method} #{args.join " "}`
      else
        raise Error, "Unrecognized command \"#{method}\". Please consult `tracy help`."
      end
    end

  end
end