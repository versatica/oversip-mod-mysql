# oversip-mod-mysql

## Overview

`oversip-mod-mysql` provides an easy to use MySQL connector for [OverSIP](http://www.oversip.net) proxy based on [mysql2](https://github.com/brianmario/mysql2) driver.

Starting from version 0.1.0 `oversip-mod-mysql` depends on [OverSIP](http://www.oversip.net) >= 1.3.0 which enforces the usage of "sync" style coding via [em-synchrony](https://github.com/igrigorik/em-synchrony/) Gem.

* For more information about `em-synchrony` usage check [Untangling Evented Code with Ruby Fibers](http://www.igvita.com/2010/03/22/untangling-evented-code-with-ruby-fibers/).

Check the [mysql2 documentation](https://github.com/brianmario/mysql2/blob/master/README.md) for the exact syntax and usage of the MySQL queries.


## API


### Method `OverSIP:M:Mysql.add_pool(options, db_data)`

Creates a MySQL connection pool. Parameters:

* `options`: A mandatory `Hash` with the following fields:
   * `:name`: Mandatory field. Must be a `Symbol` with the name for this pool.
   * `:pool_size`: The number of parallel MySQL connections to perform. By default 10.

* `db_data`: A mandatory `Hash` that will be passed to [`Mysql2::EM::Client.new`](https://github.com/brianmario/mysql2#connection-options).

The method allows passing a block which would be later called by passing as argument each generated `Mysql2::EM::Client` instance.

The created connection pool is an instance of [`EventMachine::Synchrony::ConnectionPool`](https://github.com/igrigorik/em-synchrony/blob/master/lib/em-synchrony/connection_pool.rb).


### Method `OverSIP:M:Mysql.pool(name)`

Retrieves a previously created pool with the given name. Raises an `ArgumentError` if the given name does not exist in the list of created pools.



## Usage Example

On top of `/etc/oversip/server.rb`:

```
require "oversip-mod-mysql"
```


Within the `OverSIP::SipEvents.on_initialize()` method in `/etc/oversip/server.rb`:

```
def (OverSIP::SystemEvents).on_initialize
  OverSIP::M::Mysql.add_pool(
    {
      :name => :my_db,
      :pool_size => 5,
      :synchrony => true
    },
    {
      :host => "localhost",
      :username => "oversip",
      :password => "xxxxxx",
      :database => "oversip",
      :cast_booleans => true,
      :symbolize_keys => true
    } do |conn|
      log_info "MySQL created instance: #{conn.inspect}"
    end
  )
end
```

Somewhere within the `OverSIP::SipEvents.on_request()` method in `/etc/oversip/server.rb`:

```
pool = OverSIP::M::Mysql.pool(:my_db)

begin
  result = pool.query "SELECT * FROM users WHERE user = \'#{request.from.user}\'"
  log_info "DB query result: #{result.to_a.inspect}"
  if result.any?
    # Add a X-Header with value the 'custom_header' field of the table row:
    request.set_header "X-Header", result.first["custom_header"]
    proxy = ::OverSIP::SIP::Proxy.new :proxy_out
    proxy.route request
    return
  else
    request.reply 404, "User not found in DB"
    return
  end

rescue ::Mysql2::Error => e
  log_error "DB query error:"
  log_error e
  request.reply 500, "DB query error"
  return
end
```


## Dependencies

* Ruby > 1.9.2.
* [oversip](http://www.oversip.net) Gem >= 1.3.0.
* MySQL development library (the package `libmysqlclient-dev` in Debian/Ubuntu).


## Installation

```
~$ gem install oversip-mod-mysql
```


## Author

Iñaki Baz Castillo
* Mail: ibc@aliax.net
* Github profile: [@ibc](https://github.com/ibc))
