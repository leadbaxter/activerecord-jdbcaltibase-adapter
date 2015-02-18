module ArJdbc
  module Altibase
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
  end
end
