`cd ext/stack_tracy && ruby extconf.rb`
`cd ext/stack_tracy && make`

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "stack_tracy"

class Shouter
  def self.foo
  end

  def shout(s)
    puts s
  end
end

s = Shouter.new

s.shout "A"
StackTracy.start
s.shout "B"
s.shout "B"
StackTracy.print []
s.shout "B"
s.shout "B"
a = []
a.push "asdf"
Shouter.foo
s.shout "B"
s.shout "B"
StackTracy.stop
s.shout "C"

stack_tracy do
  s.shout "D"
  sleep 0.3841
  sleep 0.9503
  sleep 0.2094
end