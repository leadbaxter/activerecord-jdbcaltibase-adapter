module ArJdbc
  module Altibase

    ADAPTER_NAME = 'Altibase'.freeze

    # @override
    def adapter_name
      ADAPTER_NAME
    end

    module Column

      # Answer the mapping for SQL data types. Hard-coded numbers represent the values Altibase holds for data types.
      def self.type_map
        @type_map ||= {
            # Number
            float:	  6,
            numeric:  2,
            double:	  8,
            real:	    7,
            bigint:	  -5, # (UInt)
            integer:  4,
            smallint: 5,

            # Date/Time
            date:     9,

            # Character/Binary
            char:     1,
            varchar:  12,
            nchar:    -8,
            nvarchar: -9,
            byte:     20001,
            nibble:   20002,
            bit:      -7,
            varbit:   -100,
            blob:     30,
            clob:     40,
            geometry: 10003
        }
      end

      # Answer the SQL type represented by the given Altibase (integer) constant.
      # @see: http://support.altibase.com/manual/en/551b/html/LogAnalyzer/ch03s03.html
      def self.sql_type_from_altibase(altibase_constant)
        type_map.key altibase_constant.to_i
      end

      class SqlAdapter
        attr_reader :row

        def initialize(row)
          @row = row
        end

        def jdbc_column_type
          sql_type = Column.sql_type_from_altibase data_type
          case sql_type
          when :varchar
            "#{sql_type}(#{precision})"
          when :float, :numeric, :double, :real
            if row['scale'].blank?
              "#{sql_type}(#{precision}, )"
            else
              "#{sql_type}(#{precision}, #{scale})"
            end
          else
            sql_type
          end
        end
        alias :type :jdbc_column_type

        def name
          row['column_name'].downcase
        end

        def data_type
          row['data_type']
        end

        def precision
          row['precision']
        end

        def scale
          row['scale']
        end

        def default_value
          row['default_val']
        end

        def null_allowed?
          row['is_nullable'] == 'T'
        end
        alias :null? :null_allowed?
        alias :nullable? :null_allowed?

      end
    end
  end
end
