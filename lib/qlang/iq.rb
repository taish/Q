module Qlang
  module Iq
    class Dydx::Algebra::Formula
      # FIX:
      def to_q
        str = to_s.gsub(/\*\*/, '^').rm(' * ')
        str.equalize!
      end
    end

    def self.execute(code)
      ruby_code = Q.to_ruby.compile(code)
      ruby_obj = eval(ruby_code)

      optimize_output(ruby_obj)
    rescue SyntaxError
      # TODO: emergency
      case ruby_code
      when /(\d)+(\w)/
        execute("#{$1} * #{$2}")
      end
    end

    def self.optimize_output(ruby_obj)
      case ruby_obj
      when Matrix, Vector, Dydx::Algebra::Formula
        ruby_obj.to_q
      when Float::INFINITY
        'oo'
      when - Float::INFINITY
        '-oo'
      else
        str = ruby_obj.to_s
        str.equalize!
      end
    end

  end
end
