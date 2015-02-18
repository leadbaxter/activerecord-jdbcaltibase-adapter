module ActiveRecord
  module ConnectionAdapters

    class AltibaseAdapter < JdbcAdapter

      include ArJdbc::Altibase

      def initialize(*args)
        super # configure_connection happens in super
      end

      ADAPTER_NAME = 'Altibase'.freeze

      # @override
      def adapter_name
        ADAPTER_NAME
      end

    end

    def jdbc_connection_class(spec)
      ::ArJdbc::Altibase.jdbc_connection_class
    end

    class AltibaseColumn < JdbcColumn # :nodoc:

      # Maps Altibase-specific data types to logical Rails types.
      def simplified_type(field_type)
        case field_type
        when /bit|nibble|byte/i
          :binary

        # Altibase DATE stores the date and time to the second
        when /date/i
          :datetime

        else
          super
        end
      end

    end

    class AltibaseJdbcConnection < JdbcConnection

      include ArJdbc::Altibase::SequencerSql

      def initialize(*args)
        @quoted_tables, @quoted_columns = {}, {}
        super # configure_connection happens in super
      end

      def setup_connection_factory
        super
        puts "Altibase database version: #{connection.database_version}"
      end

      def rollback_database
        adapter.rollback_database
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
