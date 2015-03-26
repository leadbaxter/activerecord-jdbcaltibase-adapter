# Activerecord::JdbcAltibase::Adapter

This gem provides ActiveRecord support for Altibase database. The implementation is based on JdbcAdapter
and is only intended for use with JRuby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-jdbcaltibase-adapter', :git => 'https://github.com/leadbaxter/activerecord-jdbcaltibase-adapter.git', platform: :jruby
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

## Contributing

1. Fork it ( https://github.com/leadbaxter/activerecord-jdbcaltibase-adapter/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
