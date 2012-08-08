module Kernel

  def stack_tracy(target_file)
    StackTracy.start
    yield
    StackTracy.stop
    StackTracy.dump target_file if target_file
  end

end