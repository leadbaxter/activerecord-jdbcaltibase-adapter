# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activerecord/jdbcaltibase/adapter/version'

Gem::Specification.new do |spec|
  spec.name          = 'activerecord-jdbcaltibase-adapter'
  spec.version       = Activerecord::JdbcAltibase::Adapter::VERSION
  spec.authors       = ['Brian Jackson']
  spec.email         = ['brianj2@gmail.com']
  spec.summary       = %q{ActiveRecord driver for Altibase using JDBC running under JRuby.}
  spec.description   = %q{This is an ActiveRecord driver for Altibase using JDBC running under JRuby.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_runtime_dependency 'activerecord-jdbc-adapter'
  spec.add_runtime_dependency 'jdbc-altibase'
end
