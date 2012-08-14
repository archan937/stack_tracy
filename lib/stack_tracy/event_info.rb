# See http://stackoverflow.com/questions/9607554/ruby-invalid-byte-sequence-in-utf-8

# encoding: UTF-8

module StackTracy
  class EventInfo
    attr_reader :event, :file, :line, :singleton, :object, :method, :nsec

    def self.to_hashes(csv)
      CSV.parse(csv.force_encoding("ISO-8859-1").encode("utf-8", replace: nil), :headers => true, :col_sep => ";").collect do |row|
        {
          :event => row[0]     , :file => row[1]     , :line => row[2].to_i, :singleton => row[3] == "true", :object   => "#{row[4]}" , :method => row[5],
          :nsec  => row[6].to_f, :time => row[7].to_f, :call => row[8]     , :depth     => row[9].to_i     , :duration => row[10].to_f
        }
      end
    end

    def call?
      !!event.match(/call$/)
    end

    def return?
      !!event.match(/return$/)
    end

    def matches?(arg)
      case arg.class.name
      when "StackTracy::EventInfo"
        matches? arg.call
      when "String"
        if call == arg
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
      nsec - other.nsec if other.is_a? EventInfo
    end

    def to_hash(first = nil)
      {
        :event => event, :file => file, :line => line, :singleton => singleton, :object => object,
        :method => method, :nsec => nsec, :time => (first ? self - first : nil), :call => call
      }
    end

    def call
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