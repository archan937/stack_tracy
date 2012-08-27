class String
  def tracy(&block)
    yield if block
  end
end