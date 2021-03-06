require 'qlang/api'

require 'qlang/lexer/cont_lexer'
require 'qlang/lexer/func_lexer'

require 'qlang/parser/base'
require 'qlang/parser/matrix_parser'
require 'qlang/parser/vector_parser'
require 'qlang/parser/list_parser'
require 'qlang/parser/func_parser'
require 'qlang/parser/integral_parser'
require 'qlang/parser/formula_parser'

module Qlang
  module Parser
    include Lexer::Tokens
    SYM = '\w+'
    ONEHASH = "#{ANYSP}#{SYM}#{CLN}#{ANYSP}#{VARNUM}#{ANYSP}" # sdf: 234
    def execute(lexed)
      time = Time.now
      until lexed.token_str =~ /\A(:NLIN\d|:R\d)+\z/
        fail "I'm so sorry, something wrong. Please feel free to report this." if Time.now > time + 10

        case lexed.token_str
        when /(:vector)(\d)/, /(:matrix)(\d)/, /(:tmatrix)(\d)/, /(:integral)(\d)/, /(:def_func)(\d)/
          token_sym = $1.delete(':').to_sym
          token_position = $2.to_i
          token_val = lexed.lexeds[token_position][token_sym]

          parsed = case token_sym
          when :vector
            VectorParser.execute(token_val)
          when :matrix
            MatrixParser.execute(token_val)
          when :tmatrix
            MatrixParser.execute(token_val, trans: true)
          when :integral
            IntegralParser.execute(token_val)
          when :def_func
            FuncParser.execute(token_val)
          end
          lexed.parsed!(parsed, token_position)

        when /:LPRN(\d):CONT\d:RPRN(\d)/
          tokens_range = $1.to_i..$2.to_i
          token_val = lexed.lexeds[tokens_range.to_a[1]][:CONT]

          cont_lexed = Lexer::ContLexer.new(token_val)
          cont = cont_lexed.values.join(' ')
          lexed.parsed!(cont.parentheses, tokens_range)

        when /:LBRC(\d):CONT\d:RBRC(\d)/
          tokens_range = $1.to_i..$2.to_i
          token_val = lexed.lexeds[tokens_range.to_a[1]][:CONT]

          cont = case token_val
            when %r@#{ONEHASH}(#{CMA}#{ONEHASH})*@
              ListParser.execute(token_val)
            else
              token_val
            end

          lexed.parsed!(cont, tokens_range)

        when /:eval_func(\d)/
          token_val = lexed.get_value($1)
          lexed.parsed!(token_val.parentheses, $1)

        when /:differential(\d)/
          token_position = $1.to_i
          cont = lexed.get_value(token_position)
          cont =~ /(d\/d[a-zA-Z]) (.*)/
          cont = "#{$1}(#{FormulaParser.execute($2)})"
          # FIX: Refactor
          #cont.gsub!(/(d\/d[a-zA-Z]) (.*)/, "\1(\2)")
          lexed.parsed!(cont.parentheses, token_position)
        when /:CONT(\d)/
          lexed.parsed!(lexed.get_value($1), $1)
        end
        lexed.squash!(($1.to_i)..($1.to_i+1)) if lexed.token_str =~ /(?::CONT|:R)(\d)(?::CONT|:R)(\d)/
      end

      lexed.values.join
    end
    module_function :execute
  end
end
