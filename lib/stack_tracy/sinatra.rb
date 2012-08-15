module StackTracy
  class Sinatra

    def initialize(app, arg = nil, options = {}, &before_filter)
      @app = app
      @arg = arg
      @options = options
      @before_filter = before_filter if block_given?
    end

    def call(env)
      trace = @before_filter.nil? || begin
        puts
        puts env.inspect
        puts
        request = ::Sinatra::Request.new(env)
        @before_filter.call request.url, request.params
      end
      if trace
        stack_tracy @arg, @options do
          @app.call(env)
        end
      else
        @app.call(env)
      end
    end

  end
end