# See http://guides.rubygems.org/c-extensions and http://www.rubyinside.com/how-to-create-a-ruby-extension-in-c-in-under-5-minutes-100.html
require "mkmf"
dir_config "stack_tracy"
create_makefile "stack_tracy"