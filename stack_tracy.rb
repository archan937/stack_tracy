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

  def shout!(s)
    shout s
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
s.shout! "B"
StackTracy.stop

s.shout "C"
puts "a"
StackTracy.print "Shouter."
puts "b"
StackTracy.print "Shouter"
puts "c"
StackTracy.print "Shouter.foo"
puts "d"
StackTracy.print "Shouter#"
puts "e"
StackTracy.print "Shouter#shout"
puts "f"
StackTracy.print "Shouter#shout*"
puts "g"

stack_tracy do
  s.shout "D"
  sleep 0.3841
  sleep 0.9503
  sleep 0.2094
end