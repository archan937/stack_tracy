# StackTracy

Investigate and detect slow methods within your stack trace

## Introduction

StackTracy is created for simply investigating your stack trace for called methods and its corresponding duration. You can filter modules / classes / methods within the output tree.

The gem is partly written in C to reduce the application performance as minimal as possible.

## Installation

### Add `StackTracy` to your Gemfile

    gem "stack_tracy"

### Install the gem dependencies

    $ bundle

## Usage

Using `StackTracy` is pretty straightforward. You can either `start` and `stop` stack events recording.

    [1] pry(main)> StackTracy.start
    [2] pry(main)> puts "testing"
    [3] pry(main)> StackTracy.stop

Or you can use the `stack_tracy` convenience method which records stack events within the passed block.

    [1] pry(main)> stack_tracy do
    [1] pry(main)>   puts "testing"
    [1] pry(main)> end

Once you have recorded stack events, you can call the following methods:

`StackTracy.stack_trace` - returns all recorded stack events (`array` of `StackTracy::EventInfo` instances)

    [2] pry(main)> StackTracy.stack_trace.inspect
    => ["Kernel#puts", "IO#puts", "IO#write", "IO#write", "IO#write", "IO#write", "IO#puts", "Kernel#puts"]

`StackTracy.select` - returns (optionally filtered) recorded stack events for printing purposes (`array` of `Hash` instances)

    [3] pry(main)> StackTracy.select.inspect
    => [
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>"Kernel", :method=>"puts", :nsec=>1344464282852728064, :call=>"Kernel#puts", :depth=>0, :duration=>0.000129024},
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>"IO", :method=>"puts", :nsec=>1344464282852748032, :call=>"IO#puts", :depth=>1, :duration=>9.7024e-05},
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>"IO", :method=>"write", :nsec=>1344464282852762112, :call=>"IO#write", :depth=>2, :duration=>3.4816e-05},
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>"IO", :method=>"write", :nsec=>1344464282852811008, :call=>"IO#write", :depth=>2, :duration=>2.0992e-05}
    ]

    [4] pry(main)> StackTracy.select(%w(Kernel)).inspect
    => [
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>"Kernel", :method=>"puts", :nsec=>1344464282852728064, :call=>"Kernel#puts", :depth=>0, :duration=>0.000129024}
    ]

    [5] pry(main)> StackTracy.select("Kernel IO#puts").inspect
    => [
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>"Kernel", :method=>"puts", :nsec=>1344464282852728064, :call=>"Kernel#puts", :depth=>0, :duration=>0.000129024},
      {:event=>"c-call", :file=>"(pry)", :line=>2, :singleton=>false, :object=>"IO", :method=>"puts", :nsec=>1344464282852748032, :call=>"IO#puts", :depth=>1, :duration=>9.7024e-05}
    ]

`StackTracy.print` - prints (optionally filtered) recorded stack events as a tree

    [6] pry(main)> StackTracy.print
    Kernel#puts <0.000094>
       IO#puts <0.000069>
          IO#write <0.000018>
          IO#write <0.000016>
    => nil

## Using the console

The StackTracy repo is provided with `script/console` which you can use for development / testing purposes.

Run the following command in your console:

    $ script/console
    Loading development environment (StackTracy 0.1.0)
    [1] pry(main)> stack_tracy do
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

* Provide writing stack trace data to (CSV) files
* Display results within a HTML page
* Hook into Sinatra requests

## Contact me

For support, remarks and requests, please mail me at [paul.engel@holder.nl](mailto:paul.engel@holder.nl).

## Credit

A part of the StackTracy C implementation is based on [rbtrace](https://github.com/tmm1/rbtrace) and [ruby-prof](https://github.com/rdp/ruby-prof).

## License

Copyright (c) 2012 Paul Engel, released under the MIT license

[http://holder.nl](http://holder.nl) - [http://codehero.es](http://codehero.es) - [http://gettopup.com](http://gettopup.com) - [http://github.com/archan937](http://github.com/archan937) - [http://twitter.com/archan937](http://twitter.com/archan937) - [paul.engel@holder.nl](mailto:paul.engel@holder.nl)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.