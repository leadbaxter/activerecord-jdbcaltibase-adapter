module ArJdbc
  module Altibase

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
      types[:primary_key] = { :name => 'INTEGER' }
      types[:string]      = { :name => 'VARCHAR', :limit => 255 }
      types[:integer]     = { :name => 'INTEGER' }
      types[:float]       = { :name => 'FLOAT' }
      types[:decimal]     = { :name => 'DECIMAL' }
      types[:datetime]    = { :name => 'DATETIME YEAR TO FRACTION(5)' }
      types[:timestamp]   = { :name => 'DATETIME YEAR TO FRACTION(5)' }
      types[:time]        = { :name => 'DATETIME HOUR TO FRACTION(5)' }
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
          IN (SELECT table_id FROM system_.sys_tables_ WHERE table_name = '#{table_name.to_s.upcase}')
      SQL
    end

  end

end