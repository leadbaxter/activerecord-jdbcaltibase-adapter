module ActiveRecord
  module ConnectionAdapters
    class AltibaseAdapter < JdbcAdapter

      include ArJdbc::Altibase

      def initialize(*args)
        super # configure_connection happens in super
      end

    end

    module SequencerSql
      def username
        config[:username]
      end

      def sequence_sql(name)
        <<-SQL
          CREATE SEQUENCE #{username}.SEQ_#{name.upcase}_ID
          START WITH 1
          MINVALUE 1
          MAXVALUE 268435455
          CYCLE;
        SQL
      end

      def drop_sequence_sql(name)
        "DROP SEQUENCE #{username}.SEQ_#{name}_ID;"
      end

      def procedure_sql(name)
        <<-SQL
          CREATE OR REPLACE PROCEDURE #{username}.AUTO_#{name.upcase}_ID(fld OUT NUMBER) IS
          BEGIN
          SELECT SEQ_#{name.upcase}_ID.NEXTVAL INTO FLD FROM DUAL;
          END AUTO_#{name.upcase}_ID;
        SQL
      end

      def drop_procedure_sql(name)
        "DROP PROCEDURE #{username}.AUTO_#{name.upcase}_ID;"
      end

      def trigger_sql(name)
        <<-SQL
          CREATE OR REPLACE TRIGGER #{username}.#{name.upcase}_ID_TGR
          BEFORE INSERT ON #{username}.#{name.pluralize.upcase}
          REFERENCING NEW ROW AS NEW_ROW
          FOR EACH ROW
          AS
          BEGIN
          AUTO_#{name.upcase}_ID(NEW_ROW.ID);
          END;
        SQL
      end

      def drop_trigger_sql(name)
        "DROP TRIGGER #{username}.#{name.upcase}_ID_TGR;"
      end

    end

    class AltibaseJdbcConnection < JdbcConnection

      include SequencerSql

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
