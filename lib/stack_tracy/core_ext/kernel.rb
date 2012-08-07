module Kernel

  def stack_tracy
    StackTracy.start
    yield
    StackTracy.stop
  end

end