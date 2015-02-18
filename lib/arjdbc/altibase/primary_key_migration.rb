module ArJdbc
  module Altibase

    # @todo - move to a better location for reuse
    module PrimaryKeyMigration

      def sequence_name(model_name)
        "seq_#{model_name}_id"
      end

      def trigger_name(model_name)
        "#{model_name}_id_tgr"
      end

      def procedure_name(model_name)
        "auto_#{model_name}_id"
      end

      def add_sequence(name)
        say "adding sequence: #{sequence_name name}"
        sql = raw_connection.create_sequence_sql name
        execute sql
      end

      def drop_sequence(name)
        say "dropping sequence: #{sequence_name name}"
        sql = raw_connection.drop_sequence_sql name
        execute sql
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
