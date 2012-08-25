require "sinatra"
require "stack_tracy"

use StackTracy::Sinatra, :open, :threshold => 0.002, :limit => 250

get "/" do
  "Hello World!"
end