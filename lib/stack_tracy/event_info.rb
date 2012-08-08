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
          captures = arg.match(/^([\w:]*\*?)?(\.|\#)?(\w*\*?)?$/).captures
          object_match?(captures[0]) && singleton_match?(captures[1]) && method_match?(captures[2])
        end
      else
        false
      end
    end

    def -(other)
      (nsec - other.nsec) / 1000000000.0 if other.is_a? EventInfo
    end

    def to_hash
      {:event => event, :file => file, :line => line, :singleton => singleton, :object => object, :method => method, :nsec => nsec, :call => to_s}
    end

    def to_s
      "#{object}#{singleton ? "." : "#"}#{method}"
    end

  private

    def object_match?(arg)
      (arg.to_s == "") || (object =~ /^#{arg.gsub("*", "\\w*(::\\w*)*")}$/)
    end

    def singleton_match?(arg)
      arg.nil? || ((singleton ? "." : "#") == arg)
    end

    def method_match?(arg)
      (arg.to_s == "") || (method =~ /^#{arg.gsub("*", "\\w*")}$/)
    end

  end
end