require "sinatra"
require "stack_tracy"

use StackTracy::Sinatra, :open

get "/" do
  "Hello World!"
end