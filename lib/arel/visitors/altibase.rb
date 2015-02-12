require 'arel/visitors/compat'

module Arel
  module Visitors
    class Altibase < Arel::Visitors::ToSql

      #alias :old_quote :quote

      def quote(value, column = nil)
        return value.to_sql if Arel::Nodes::NamedFunction === value
        #old_quote value, column
        super
      end

      # def visit_Date(o, a)
      #   puts "visit_Date(#{o}, #{a})"
      # end

      # def visit_DateTime(o, a)
      #   puts "visit_DateTime(#{o}, #{a})"
      # end

    end
  end
end
