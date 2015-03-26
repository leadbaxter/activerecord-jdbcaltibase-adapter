# Activerecord::JdbcAltibase::Adapter

This gem provides ActiveRecord support for Altibase database. The implementation is based on JdbcAdapter
and is only intended for use with JRuby.

## Installation

Add the following to your application's Gemfile:

```ruby
# Use jdbcaltibase for Active Record
gem 'jdbc-altibase', :github => 'leadbaxter/jdbc-altibase', platform: :jruby
gem 'activerecord-jdbcaltibase-adapter', :github => 'leadbaxter/activerecord-jdbcaltibase-adapter', platform: :jruby
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-jdbcaltibase-adapter

## Usage

### Add a sequence to support the primary key (id):

```ruby
class User < ActiveRecord::Base
  self.sequence_name = 'SEQ_USER_ID'
end
```

### Add support for migrations

The following code snippet will illustrate what is needed in order for an Altibase table to support migrations:

```ruby
class CreateUsers < ActiveRecord::Altibase::Migration
  def change
    create_table(:users) do |t|
      t.string :name, null: false
      t.string :email, null: false

      t.timestamps
    end

    add_primary_key :users
  end
end
```

#### Notice specifically the Migration class extends the provided Altibase implementation
```ruby
  ActiveRecord::Altibase::Migration
```

#### Finally, the following line is required:
```ruby
  add_primary_key :users
```
### In summary:
1. For ActiveRecord model:
   - assign the ```self.sequence_name```

2. For any migration classes you create:
   - Change the base class from ```ActiveRecord::Migration``` to ```ActiveRecord::Altibase::Migration```
   - Add the primary key using ```add_primary_key :model_name```

## Contributing

1. Fork it ( https://github.com/leadbaxter/activerecord-jdbcaltibase-adapter/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
