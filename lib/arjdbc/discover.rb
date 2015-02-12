# arjdbc/discover.rb: Declare ArJdbc.extension modules in this file
# that loads a custom module and adapter.

module ::ArJdbc
  extension :Altibase do |name|
    if name =~ /altibase/i
      require 'arjdbc/altibase'
      true
    end
  end
end