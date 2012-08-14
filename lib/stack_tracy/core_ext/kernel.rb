require "securerandom"

module Kernel

  def stack_tracy(arg = nil, options = {})
    if arg.is_a?(Hash)
      options = arg
      arg = nil
    end
    StackTracy.start options
    yield
    StackTracy.stop
    if arg == :print
      StackTracy.print
    elsif arg == :dump
      StackTracy.dump "stack_events.csv"
    elsif arg == :open
      tmp_file = "#{Dir::tmpdir}/stack_events-#{SecureRandom.hex(3)}.csv"
      StackTracy.dump tmp_file
      StackTracy.open tmp_file
    elsif arg.is_a? String
      StackTracy.dump arg
    end
    nil
  end

end