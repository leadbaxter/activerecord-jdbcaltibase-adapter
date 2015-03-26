ArJdbc::ConnectionMethods.module_eval do
  def altibase_connection(config)
    config[:driver] = 'Altibase.jdbc.driver.AltibaseDriver'
    config[:connection_alive_sql] = 'SELECT 1 FROM DUAL'
    config[:encoding] ||= 'UTF-16'
    config[:adapter_spec] = ArJdbc::Altibase
    config[:adapter_class] = ::ActiveRecord::ConnectionAdapters::AltibaseAdapter
    jdbc_connection(config)
  end
end