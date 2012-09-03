# oversip-mod-mysql

`oversip-mod-mysql` provides an easy to use MySQL connector for [OverSIP](http://www.oversip.net) proxy based on [mysql2](https://github.com/brianmario/mysql2) driver. The library allows both pure async style (via callbacks) or serial style (by using [em-synchrony](https://github.com/igrigorik/em-synchrony/) Gem).





## API


### `OverSIP:M:Mysql.add_pool(options, db_data)`

Creates a MySQL connection pool. Parameters:

* `options`: A mandatory `Hash` with the following fields:
   * `:name`: Mandatory field. Must be a `Symbol` with the name for this pool.
   * `:pool_size`: The number of parallel MySQL connections to perform. By default 10.
   * `:synchrony`: Whether to use [em-synchrony](https://github.com/igrigorik/em-synchrony/) or not. By default `false`.

* `db_data`: A mandatory `Hash` that will be passed to [`Mysql2::EM::Client.new`](https://github.com/brianmario/mysql2#connection-options).

*NOTE:* There is no need to pass the option `:async => true` in `db_data`. That is automatically done by the library.


### `OverSIP:M:Mysql.pool(name)`

Retrieves a previously created pool with the given name. Raises an `ArgumentError` if the given name does not exist in the list of created pools.




## Pure async style usage

When creating a pool with `options[:synchrony] => false` (default behaviour) the obtained pool is a [`EventMachine::Pool`](https://github.com/ibc/EventMachine-LE/blob/master/lib/em/pool.rb) instance and thus, it requires the following usage:


### Example

On top of `/etc/oversip/server.rb`:

```
require "oversip-mod-mysql"

OverSIP::M::Mysql.add_pool(
  { :name => :my_async_db, :pool_size => 5, :synchrony => false},
  { :host => "localhost", :username => "oversip", :password => "xxxxxx", :database => "oversip"}
)
```

Somewhere within the `OverSIP::SipEvents.on_request()` method in `server.rb`:

```
pool = OverSIP::M::Mysql.pool(:my_async_db)

pool.perform do |db_conn|
  query = db_conn.query "SELECT * FROM users WHERE user = \'#{request.ruri.user}\'"

  query.callback do |result|
    log_info "DB async query result: #{result.to_a.inspect}"
    if result.any?
      proxy = ::OverSIP::SIP::Proxy.new
      proxy.route request
    else
      request.reply 404, "Destination user not found in DB"
    end
  end

  query.errback do |error|
    log_error "DB async query error: #{error.inspect}"
    request.reply 500, "DB async query error"
  end
end
```


## Sync style usage with `em-synchrony`

When creating a pool with `options[:synchrony] => true`  the obtained pool is a [`EventMachine::Synchrony::ConnectionPool`](https://github.com/igrigorik/em-synchrony/blob/master/lib/em-synchrony/connection_pool.rb) instance.

Please ensure you properly understand how [em-synchrony](https://github.com/igrigorik/em-synchrony/) works. Specially take into account that just the code within the `EM.synchrony do [...] end` block is executed serially. Code placed after that block is executed immediately, this is, *before* the serial code is executed. So if you want to use serial style coding write all your logic code within a `EM.synchrony do [...] end` block.

* For more information about `em-synchrony` usage check [Untangling Evented Code with Ruby Fibers](http://www.igvita.com/2010/03/22/untangling-evented-code-with-ruby-fibers/).


### Example

On top of `/etc/oversip/server.rb`:

```
require "oversip-mod-mysql"

OverSIP::M::Mysql.add_pool(
  { :name => :my_sync_db, :pool_size => 5, :synchrony => true},
  { :host => "localhost", :username => "oversip", :password => "xxxxxx", :database => "oversip"}
)
```

Somewhere within the `OverSIP::SipEvents.on_request()` method in `server.rb`:

```
EM.synchrony do
  pool = OverSIP::M::Mysql.pool(:my_sync_db)

  begin
    result = pool.query "SELECT * FROM users WHERE user = \'#{request.ruri.user}\'"
    log_info "DB sync query result: #{result.to_a.inspect}"
    if result.any?
      proxy = ::OverSIP::SIP::Proxy.new :proxy_out
      proxy.route request
    else
      request.reply 404, "Destination user not found in DB"
    end

  rescue ::Mysql2::Error => e
    log_error "DB sync query error:"
    log_error e
    request.reply 500, "DB sync query error"
  end
end
```


### Using Sync and Async Styles Together

A pool created with `OverSIP:M:Mysql.add_pool()` method must be sync or async. However the user can set two pools, the first one sync and the second one sync.

When a sync pool is created, the library loads `em-synchrony/mysql2` which overrides the `Mysql2::EM::Client#query()` method. So if *at least* one of your pools uses sync style then you must use the `Mysql2::EM::Client#aquery()` method for the async pool (which is an alias of the original `query()` method).


## Installation

```
~$ gem install oversip-mod-mysql
```


## Author

Iñaki Baz Castillo <ibc@aliax.net> (Github [@ibc](https://github.com/ibc)).
