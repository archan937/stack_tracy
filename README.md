# StackTracy

Investigate and detect slow methods within the stack trace of your Ruby (optionally Sinatra) application

## Introduction

StackTracy is created for simply investigating your stack trace for called methods and its corresponding duration. You can filter modules / classes / methods within the output tree.

The gem is partly written in C to reduce the application performance as minimal as possible.

![Dick .. Stack Tracy](http://codehero.es/images/stack_tracy.jpg)

Watch the ["**Using StackTracy within a small Sinatra application**"](https://vimeo.com/archan937/stacktracy) **screencast** to see StackTracy in action!

## Installation

### Add `StackTracy` to your Gemfile

    gem "stack_tracy"

### Install the gem dependencies

    $ bundle

## Usage

### Recording stack events

Using `StackTracy` is pretty straightforward. You can either `start` and `stop` stack events recording.

    [1] pry(main)> StackTracy.start
    [2] pry(main)> puts "testing"
    [3] pry(main)> StackTracy.stop

Or you can use the `stack_tracy` convenience method which records stack events within the passed block.

    [1] pry(main)> stack_tracy do
    [1] pry(main)>   puts "testing"
    [1] pry(main)> end

### Reducing recorded stack events

As StackTracy records every `call` and `return` event, the resulted stack tree can get immense huge. Fortunately, you can reduce the recorded stack events by passing options to `StackTracy.start` or `stack_tracy`.

They accept an options `Hash` with at least one of the following keys:

* `:only` - Matching events will be recorded
* `:exclude` - Matching events will be ignored

The value can be either a String (optionally whitespace-delimited) or an array of strings containing `class` and/or `module` names. You can use the wildcard (`*`) for matching classes and/or modules within that namespace.

#### Some examples

You can pass options as follows:

    [1] pry(main)> StackTracy.start :only => ["Foo"]

When using the convenience method:

    [2] pry(main)> stack_tracy(:only => "Foo") { puts "testing" }
    [3] pry(main)> stack_tracy(:dump, {:only => "Foo*"}) { puts "testing" }
    [4] pry(main)> stack_tracy(:open, {:exclude => ["Array", "Hash"]}) { puts "testing" }

Let's say that you have the following code:

    class Foo
      class Bar; end
      module CandyBar; end
    end

    class FooBar; end

A couple of examples:

* `:only => "Foo"` records `Foo`
* `:only => "Foo*"` records `Foo`, `Foo::Bar` and `Foo::CandyBar`
* `:only => "Foo*", :exclude => "Foo::Bar"` records `Foo` and `Foo::CandyBar`
* `:exclude => ["Foo*", "FooBar"]` records everything except for `Foo`, `Foo::Bar`, `Foo::CandyBar` and `FooBar`
* `:only => "Foo* Kernel"` records `Foo`, `Foo::Bar`, `Foo::CandyBar` and `Kernel`

### Configure StackTracy

You can configure `StackTracy` regarding the default stack tree reduction behaviour, its dump directory and whether to include the source location when dumping recorded stack events:

    StackTracy.configure do |c|
      c.dump_dir             = "."                        #=> default: Dir::tmpdir
      c.dump_source_location = "."                        #=> default: false
      c.limit                = 1000                       #=> default: 7500
      c.threshold            = 0.005                      #=> default: 0.001
      c.only                 = "Foo*"                     #=> default: nil
      c.exclude              = %w(Foo::Bar Foo::CandyBar) #=> default: nil
    end

### Using recorded stack events

Once you have recorded stack events, you can call the following methods:

`StackTracy.stack_trace` - returns all recorded stack events (`array` of `StackTracy::EventInfo` instances)

    [2] pry(main)> StackTracy.stack_trace.inspect
    => [
      #<StackTracy::EventInfo:0x0000010154b418 @event="c-call", @file="(pry)", @line=2, @singleton=false, @object=Kernel, @method="puts", @nsec=1344465432463251968>,
      #<StackTracy::EventInfo:0x0000010154b350 @event="c-call", @file="(pry)", @line=2, @singleton=false, @object=IO, @method="puts", @nsec=1344465432463272960>,
      #<StackTracy::EventInfo:0x0000010154b1c0 @event="c-call", @file="(pry)", @line=2, @singleton=false, @object=IO, @method="write", @nsec=1344465432463288064>,
      #<StackTracy::EventInfo:0x0000010154b0a8 @event="c-return", @file="(pry)", @line=2, @singleton=false, @object=IO, @method="write", @nsec=1344465432463331072>,
      #<StackTracy::EventInfo:0x0000010154af68 @event="c-call", @file="(pry)", @line=2, @singleton=false, @object=IO, @method="write", @nsec=1344465432463344896>,
      #<StackTracy::EventInfo:0x0000010154ae50 @event="c-return", @file="(pry)", @line=2, @singleton=false, @object=IO, @method="write", @nsec=1344465432463365888>,
      #<StackTracy::EventInfo:0x0000010154ad38 @event="c-return", @file="(pry)", @line=2, @singleton=false, @object=IO, @method="puts", @nsec=1344465432463378944>,
      #<StackTracy::EventInfo:0x0000010154ac20 @event="c-return", @file="(pry)", @line=2, @singleton=false, @object=Kernel, @method="puts", @nsec=1344465432463390976>]
    ]

`StackTracy.select` - returns (optionally filtered) recorded stack events for printing purposes (`array` of `Hash` instances)

    [3] pry(main)> StackTracy.select.inspect
    => [
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>Kernel, :method=>"puts", :nsec=>1344464282852728064, :call=>"Kernel#puts", :depth=>0, :duration=>0.000129024},
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>IO, :method=>"puts", :nsec=>1344464282852748032, :call=>"IO#puts", :depth=>1, :duration=>9.7024e-05},
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>IO, :method=>"write", :nsec=>1344464282852762112, :call=>"IO#write", :depth=>2, :duration=>3.4816e-05},
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>IO, :method=>"write", :nsec=>1344464282852811008, :call=>"IO#write", :depth=>2, :duration=>2.0992e-05}
    ]
    [4] pry(main)> StackTracy.select(%w(Kernel)).inspect
    => [
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>Kernel, :method=>"puts", :nsec=>1344464282852728064, :call=>"Kernel#puts", :depth=>0, :duration=>0.000129024}
    ]
    [5] pry(main)> StackTracy.select("Kernel IO#puts").inspect
    => [
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>Kernel, :method=>"puts", :nsec=>1344464282852728064, :call=>"Kernel#puts", :depth=>0, :duration=>0.000129024},
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>IO, :method=>"puts", :nsec=>1344464282852748032, :call=>"IO#puts", :depth=>1, :duration=>9.7024e-05}
    ]

`StackTracy.print` - prints (optionally filtered) recorded stack events as a tree

    [6] pry(main)> StackTracy.print
    Kernel#puts <0.000094>
       IO#puts <0.000069>
          IO#write <0.000018>
          IO#write <0.000016>
    => nil

### Writing data to CSV files

You can dump (optionally filtered) recorded stack events to a CSV file.

    [1] pry(main)> StackTracy.start
    [2] pry(main)> puts "testing"
    => testing
    [3] pry(main)> StackTracy.stop
    [4] pry(main)> StackTracy.print
    Kernel#puts <0.000121>
       IO#puts <0.000091>
          IO#write <0.000032>
          IO#write <0.000020>
    => nil
    [5] pry(main)> StackTracy.dump "result.csv"
    => true

#### CSV sample file

This is what the contents of `result.csv` would look like:

    event;;;singleton;object;method;nsec;call;depth;duration
    c-call;;;false;Kernel;puts;1344466943040581120;Kernel#puts;0;0.000120832
    c-call;;;false;IO;puts;1344466943040599040;IO#puts;1;9.1904e-05
    c-call;;;false;IO;write;1344466943040613120;IO#write;2;3.2768e-05
    c-call;;;false;IO;write;1344466943040658944;IO#write;2;1.9968e-05

When invoking `StackTracy.dump "result.csv", true` and thus including the source location:

    event;file;line;singleton;object;method;nsec;call;depth;duration
    c-call;(pry);2;false;Kernel;puts;1344466943040581120;Kernel#puts;0;0.000120832
    c-call;(pry);2;false;IO;puts;1344466943040599040;IO#puts;1;9.1904e-05
    c-call;(pry);2;false;IO;write;1344466943040613120;IO#write;2;3.2768e-05
    c-call;(pry);2;false;IO;write;1344466943040658944;IO#write;2;1.9968e-05

### Viewing stack events in your browser

You can easily view the dumped stack events within your browser by either calling the following within Ruby:

    [1] pry(main)> StackTracy.open "some/dir/file.csv"

or the following within the Terminal:

    $ tracy "some/dir/file.csv"

Your default browser will be launched in which the stack events will be displayed.

When passing no path, `tracy` will look for `stack_events-<random generated postfix>.csv` in either the default dump directory or in `Dir::tmpdir` and display it in the browser. When not found, it will display the last compiled stack tree when available:

    $ tracy

### Kernel#stack_tracy

As already mentioned, there is a convenience method called `stack_tracy` convenience method. The following shows a couple variants with its equivalent "normal implementation".

#### Without passing an argument

Record stack events executed within a block:

    [1] pry(main)> stack_tracy do
    [1] pry(main)>   puts "testing"
    [1] pry(main)> end

Its equivalent:

    [1] pry(main)> StackTracy.start
    [2] pry(main)> puts "testing"
    [3] pry(main)> StackTracy.stop

#### Passing `:print`

Record stack events executed within a block and print the stack tree:

    [1] pry(main)> stack_tracy :print do
    [1] pry(main)>   puts "testing"
    [1] pry(main)> end

Its equivalent:

    [1] pry(main)> StackTracy.start
    [2] pry(main)> puts "testing"
    [3] pry(main)> StackTracy.stop
    [4] pry(main)> StackTracy.print

#### Passing `:dump`

Record stack events executed within a block and write the obtained data to `<default dump directory>/stack_events-<random generated postfix>.csv`:

    [1] pry(main)> stack_tracy :dump do
    [1] pry(main)>   puts "testing"
    [1] pry(main)> end

Its equivalent:

    [1] pry(main)> StackTracy.start
    [2] pry(main)> puts "testing"
    [3] pry(main)> StackTracy.stop
    [4] pry(main)> StackTracy.dump

#### Passing a target directory

Record stack events executed within a block and write the obtained data to `<passed directory>/stack_events-<random generated postfix>.csv`:

    [1] pry(main)> stack_tracy Dir::tmpdir do
    [1] pry(main)>   puts "testing"
    [1] pry(main)> end

Its equivalent:

    [1] pry(main)> StackTracy.start
    [2] pry(main)> puts "testing"
    [3] pry(main)> StackTracy.stop
    [4] pry(main)> StackTracy.dump Dir::tmpdir

#### Passing a CSV file path

Record stack events executed within a block and write the obtained data to the passed file path:

    [1] pry(main)> stack_tracy "some/file.csv" do
    [1] pry(main)>   puts "testing"
    [1] pry(main)> end

Its equivalent:

    [1] pry(main)> StackTracy.start
    [2] pry(main)> puts "testing"
    [3] pry(main)> StackTracy.stop
    [4] pry(main)> StackTracy.dump "some/file.csv"

#### Passing `:open`

Record stack events executed within a block and open the stack tree in your browser:

    [1] pry(main)> stack_tracy :open do
    [1] pry(main)>   puts "testing"
    [1] pry(main)> end

Its equivalent:

    [1] pry(main)> StackTracy.start
    [2] pry(main)> puts "testing"
    [3] pry(main)> StackTracy.stop
    [4] pry(main)> StackTracy.dump do |file|
    [4] pry(main)>   StackTracy.open file, true
    [4] pry(main)> end

## Hooking into Sinatra requests

You can easily hook `StackTracy` into [Sinatra](http://www.sinatrarb.com) requests. This is a complete working example:

    require "sinatra"
    require "stack_tracy"

    use StackTracy::Sinatra, :open

    get "/" do
      "Hello world!"
    end

**Note**: Make sure you have the `sinatra` and `stack_tracy` gems installed.

Open the Sinatra application in your browser at [http://localhost:4567](http://localhost:4567) and the complete stack tree will be displayed in your browser! ^^

You can also open [http://localhost:4567/tracy](http://localhost:4567/tracy) afterwards by the way.

### Taking more control

I can imagine that you don't want to hook into every Sinatra request. So you can pass a block which will be yielded before every request. The request will traced when it does **not** return either `false` or `nil`:

    use StackTracy::Sinatra do |path, params|
      path == "/" #=> only trace "http://localhost:4567"
    end

Also, you can determine what StackTracy has to do after the request has finished. It resembles the invocation of `stack_tracy`. The following will dump every request into the current directory:

    use StackTracy::Sinatra, "."

This will immediately open the stack tree in your default browser after every traced request:

    use StackTracy::Sinatra, :open do
      path == "/paul/engel" #=> only trace and open stack tree when opening "http://localhost:4567/paul/engel"
    end

Reduce the stack tree and open it immediately:

    use StackTracy::Sinatra, :open, :only => "Foo*"

## Using the console

The StackTracy repo is provided with `script/console` which you can use for development / testing purposes.

Run the following command in your console:

    $ script/console
    Loading development environment (StackTracy 0.1.0)
    [1] pry(main)> stack_tracy :print do
    [1] pry(main)*   puts "testing"
    [1] pry(main)* end
    testing
    Kernel#puts <0.000121>
       IO#puts <0.000091>
          IO#write <0.000032>
          IO#write <0.000020>
    => nil
    [2] pry(main)>

## Testing

Run the following command for testing:

    $ rake

You can also run a single test:

    $ ruby test/unit/test_tracy.rb

## TODO

* Optimize C implementation performance when converting C data to Ruby objects within `stack_tracy_stop`
* Improve stack tree reduction by checking on method level
* Correct `StackTracy::PRESETS` regarding `:active_record` and `:data_mapper`
* Easily hook into Rails requests?

## Contact me

For support, remarks and requests, please mail me at [paul.engel@holder.nl](mailto:paul.engel@holder.nl).

## Credit

* Two functions within the StackTracy C implementation are taken from [ruby-prof](https://github.com/rdp/ruby-prof).
* The table sort within the Cumulatives tab is implemented with [TinySort](http://tinysort.sjeiti.com/).
* Being able to improve browser performance when loading heavy HTML stack trace pages using Ravi Raj's ([@raviraj4u](https://twitter.com/raviraj4u)) blog post: [http://ravirajsblog.blogspot.nl/2010/12/another-hack-to-render-heavy-html-pages.html](http://ravirajsblog.blogspot.nl/2010/12/another-hack-to-render-heavy-html-pages.html)

## License

Copyright (c) 2012 Paul Engel, released under the MIT license

[http://holder.nl](http://holder.nl) - [http://codehero.es](http://codehero.es) - [http://gettopup.com](http://gettopup.com) - [http://github.com/archan937](http://github.com/archan937) - [http://twitter.com/archan937](http://twitter.com/archan937) - [paul.engel@holder.nl](mailto:paul.engel@holder.nl)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.