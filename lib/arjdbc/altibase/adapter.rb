module ArJdbc
  module Altibase

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
        "DROP SEQUENCE #{username}.SEQ_#{name.upcase}_ID;"
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

    # @todo - move to a better location for reuse
    module PrimaryKeyMigration
      def method_missing(method, *arguments, &block)
        if /(add|drop)_(sequence|procedure|trigger)/.match method
          name = arguments[0]
          tag = {
              sequence:  "seq_#{name}_id",
              procedure: "auto_#{name}_id",
              trigger:   "#{name}_id_tgr"
          }[$2.to_sym]
          prefix, message = $1 == 'add' ? ['adding', ''] : %w(dropping drop_)
          say "#{prefix} #{$2}: #{tag}"
          sql = raw_connection.send "#{message}#{$2}_sql", name
          execute sql
        else
          super
        end
      end

      def add_primary_key_fields(table_name)
        name = table_name.to_s.singularize
        reversible do |dir|
          dir.up do
            add_primary_key name
          end

          dir.down do
            drop_primary_key name
          end
        end
      end

      def add_primary_key(name)
        add_sequence name
        #add_procedure name
        #add_trigger name
      end

      def drop_primary_key(name)
        begin drop_sequence  name; rescue; say 'ok - did not exist'; end
        #begin drop_trigger   name; rescue; say 'ok - did not exist'; end
        #begin drop_procedure name; rescue; say 'ok - did not exist'; end
      end
    end

    def self.jdbc_connection_class
      ::ActiveRecord::ConnectionAdapters::AltibaseJdbcConnection
    end

    def self.included(obj)
    end

    # Quotes the column name. Defaults to no quoting.
    def quote_column_name(name)
      @connection.quote_column_name name
    end

    # Quotes the table name. Defaults to column name quoting.
    def quote_table_name(name)
      @connection.quote_table_name name
    end

    def remove_index!(table_name, index_name) #:nodoc:
      @connection.remove_index table_name, index_name
    end

    # @see activerecord-jdbc-adapter-{version}/lib/arjdbc/jdbc/adapter.rb:581
    def table_exists?(table_name)
      table_name.present? && @connection.tables.include?(table_name.to_s.downcase)
    end

    def prefetch_primary_key?(table_name)
      true
    end

    def next_sequence_value(sequence_name)
      result_set = exec_query "SELECT #{sequence_name}.nextVal FROM DUAL"
      result_set[0]["#{sequence_name.to_s.downcase}.nextval"]
    end

    # @see activerecord-jdbc-adapter-{version}/lib/arjdbc/jdbc/adapter.rb:321
    def columns(table_name, name = nil)
      klass = jdbc_column_class
      select_columns(table_name).map do |row|
        column = Column::SqlAdapter.new row
        klass.new(config, column.name, column.default_value, column.type, column.null?)
      end
    end

    def modify_types(types)
      super(types)
      types[:primary_key] = { :name => 'INTEGER PRIMARY KEY' }
      types[:string]      = { :name => 'VARCHAR', :limit => 255 }
      types[:integer]     = { :name => 'INTEGER' }
      types[:float]       = { :name => 'FLOAT' }
      types[:decimal]     = { :name => 'DECIMAL' }
      types[:datetime]    = { :name => 'DATE' }
      types[:timestamp]   = { :name => 'DATE' }
      types[:time]        = { :name => 'DATE' }
      types[:date]        = { :name => 'DATE' }
      types[:binary]      = { :name => 'BYTE' }
      types[:boolean]     = { :name => 'BOOLEAN' }
      types
    end

    # Executes an insert statement in the context of this connection.
    #
    # WARNING: this patch is pretty much a gross hack!!!
    #
    #          All that is happening here is that instead of using
    #          @connection.execute_insert, it uses execute_query.
    #
    #          Then, ActiveRecord::JDBCError exceptions are trapped
    #          and the message is examined. If it the message says
    #          "No results were returned by the query" the result
    #          is SUCCESS.
    #
    #          There is some sort of error happening down in the Java
    #          code and this was the quickest way to get up and running.
    #
    #          For some reason the problem only occurs for execute_insert.
    #          @todo figure this out later?
    #
    # @param sql the query string (or AREL object)
    # @param name logging marker for the executed SQL statement log entry
    # @param binds the bind parameters
    # @override available since **AR-3.1**
    def exec_insert(sql, name, binds, pk = nil, sequence_name = nil)
      if sql.respond_to?(:to_sql)
        sql = to_sql(sql, binds); to_sql = true
      end
      if prepared_statements?
        log(sql, name || 'SQL', binds) { @connection.execute_query(sql, binds) }
      else
        sql = suble_binds(sql, binds) unless to_sql # deprecated behavior
        log(sql, name || 'SQL') do
          begin
            @connection.execute_query(sql)
          rescue ActiveRecord::JDBCError => ex
            ok = 'No results were returned by the query:'
            raise ex unless ex.message.start_with?(ok)
          end
          true
        end
      end
    end

    private

    # Answer a result set where each row is a column selected from the Altibase system_.sys_columns_ table.
    # @param table_name String name of the table of the columns to retrieve.
    def select_columns(table_name)
      exec_query <<-SQL
        SELECT * FROM system_.sys_columns_ WHERE table_id
          IN (#{sql_for_sys_table table_name})
      SQL
    end

    # Answer a result set where each row is a trigger selected from the Altibase system_.sys_triggers_ table.
    # @param table_name String name of the table of the columns to retrieve.
    def select_triggers(table_name)
      exec_query <<-SQL
        SELECT * FROM system_.sys_triggers_ WHERE table_id
          IN (#{sql_for_sys_table table_name})
      SQL
    end

    # Answer a string SQL for selecting the specified from the Altibase system_.sys_tables_ table.
    # @param table_name String name of the table of the columns to retrieve.
    def sql_for_sys_table(table_name)
      "SELECT table_id FROM system_.sys_tables_ WHERE table_name = '#{table_name.to_s.upcase}'"
    end

  end

end
