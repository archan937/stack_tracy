# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Engel"]
  gem.email         = ["paul.engel@holder.nl"]
  gem.summary       = %q{Investigate and detect slow methods within your stack trace}
  gem.description   = %q{Investigate and detect slow methods within your stack trace}
  gem.homepage      = "https://github.com/archan937/stack_tracy"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.extensions    = ["ext/stack_tracy/extconf.rb"]
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "stack_tracy"
  gem.require_paths = ["lib"]
  gem.version       = "0.1.0"

  gem.add_dependency "rich_support", "~> 0.1.2"
  gem.add_dependency "launchy", "2.1.0"
end