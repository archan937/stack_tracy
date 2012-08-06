module StackTracy
  class EventInfo
    attr_reader :event, :file, :line, :singleton, :object, :method, :timestamp

    def time
      Time.at timestamp
    end

    def call?
      !!event.match(/call$/)
    end

    def return?
      !!event.match(/return$/)
    end

    def matches?(other)
      to_s == other.to_s
    end

    def to_s
      "#{object}#{singleton ? "." : "#"}#{method}"
    end

  end
end