module ActiveRecord
  module ConnectionAdapters
    class AltibaseAdapter < JdbcAdapter

      include ArJdbc::Altibase

      def initialize(*args)
        super # configure_connection happens in super
      end

    end

    class AltibaseJdbcConnection < JdbcConnection

      def initialize(*args)
        @quoted_tables, @quoted_columns = {}, {}
        super # configure_connection happens in super
      end

      # Quotes the column name.
      def quote_column_name(name)
        #@quoted_columns[name] ||= Arel::Nodes::SqlLiteral === name ? name : @connection.quote_column_name(name)
        @quoted_columns[name] ||= quote_name(name)
      end

      # Quotes the table name.
      def quote_table_name(name)
        #return name if Arel::Nodes::SqlLiteral === name
        #@quoted_tables[name] ||= @connection.quote_table_name(name)
        @quoted_tables[name] ||= quote_name(name)
      end

      def quote_name(something)
        #Arel::Nodes::SqlLiteral === something ? something : "'#{something}'"
        case something
        when Arel::Nodes::SqlLiteral
          something
        when Arel::Nodes::NamedFunction
          something.to_sql
        else
          something.to_s  # no quotes needed, but returns a string
        end
      end

      def remove_index(table_name, index_name) #:nodoc:
        execute "DROP INDEX #{quote_column_name(index_name)}"
      end

    end
  end
end
