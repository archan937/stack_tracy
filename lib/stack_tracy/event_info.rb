module StackTracy
  class EventInfo
    attr_reader :event, :file, :line, :singleton, :object, :method, :nsec

    def call?
      !!event.match(/call$/)
    end

    def return?
      !!event.match(/return$/)
    end

    def matches?(other)
      to_s == other.to_s
    end

    def -(other)
      (nsec - other.nsec) / 1000000000.0 if other.is_a? EventInfo
    end

    def to_s
      "#{object}#{singleton ? "." : "#"}#{method}"
    end

  end
end