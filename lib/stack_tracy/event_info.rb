module StackTracy
  class EventInfo
    attr_reader :event, :file, :line, :singleton, :object, :method, :nsec

    def call?
      !!event.match(/call$/)
    end

    def return?
      !!event.match(/return$/)
    end

    def matches?(arg)
      case arg.class.name
      when "StackTracy::EventInfo"
        matches? arg.to_s
      when "String"
        if to_s == arg
          true
        else
          captures = arg.match(/^(\w+\*?)(\.|\#)?(\w+\*?)?$/).captures
          object_match?(captures[0]) && singleton_match?(captures[1]) && method_match?(captures[2])
        end
      else
        false
      end
    end

    def -(other)
      (nsec - other.nsec) / 1000000000.0 if other.is_a? EventInfo
    end

    def to_s
      "#{object}#{singleton ? "." : "#"}#{method}"
    end

  private

    def object_match?(arg)
      object =~ /^#{arg.gsub("*", "(::.*)?")}$/
    end

    def singleton_match?(arg)
      arg.nil? || ((singleton ? "." : "#") == arg)
    end

    def method_match?(arg)
      arg.nil? || (method =~ /^#{arg.gsub("*", ".*?")}$/)
    end

  end
end