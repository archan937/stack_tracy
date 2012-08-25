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
      StackTracy.dump
    elsif arg == :open
      file = StackTracy.dump
      StackTracy.open file, true
    elsif arg.is_a? String
      StackTracy.dump arg
    end
    nil
  end

end