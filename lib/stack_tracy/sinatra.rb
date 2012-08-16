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
      if request.path.match /^\/tracy-?(.*)?/
        return open($1)
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
      StackTracy.open match.to_s.empty? ? nil : match
      [200, {"Content-Type" => "text/html;charset=utf-8", "Content-Length" => Rack::Utils.bytesize("").to_s}, ""]
    end

  end
end