module StackTracy
  class Sinatra

    def initialize(app, arg = nil, options = {}, &before_filter)
      @app = app
      @arg = arg
      @options = options
      @before_filter = before_filter if block_given?
    end

    def call(env)
      request = ::Sinatra::Request.new env
      if request.path.match /^\/tracy(-.*)?/
        return open($1.to_s.gsub(/^-/, ""))
      end
      if @before_filter.nil? || !!@before_filter.call(request.path, request.params)
        result = nil
        stack_tracy @arg || Dir::tmpdir, @options do
          result = @app.call(env)
        end
        result
      else
        @app.call(env)
      end
    end

  private

    def open(match)
      if match.empty?
        if StackTracy.stack_trace.empty?
          StackTracy.open nil, false, @options
        else
          StackTracy.dump do |file|
            StackTracy.open file, true, @options
          end
        end
      else
        StackTracy.open match, false, @options
      end
      [200, {"Content-Type" => "text/html;charset=utf-8", "Content-Length" => Rack::Utils.bytesize("").to_s}, ""]
    end

  end
end