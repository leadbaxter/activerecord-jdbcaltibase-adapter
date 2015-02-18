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
  end
end
