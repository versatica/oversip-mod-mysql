require "oversip-mod-mysql/version.rb"

require "em-synchrony"
require "em-synchrony/mysql2"


module OverSIP
  module Modules

    module Mysql

      extend ::OverSIP::Logger

      DEFAULT_POOL_SIZE = 10

      @log_id = "Mysql module"
      @pools = {}

      def self.add_pool options, db_data
        raise ::ArgumentError, "`options' must be a Hash"  unless options.is_a? ::Hash
        raise ::ArgumentError, "`db_data' must be a Hash"  unless db_data.is_a? ::Hash

        name, pool_size = options.values_at(:name, :pool_size)
        pool_size ||= DEFAULT_POOL_SIZE

        raise ::ArgumentError, "`options[:name]' must be a Symbol"  unless name.is_a? ::Symbol
        raise ::ArgumentError, "`options[:pool_size]' must be a positive Fixnum"  unless pool_size.is_a? ::Fixnum and pool_size > 0

        # Forcing DB autoreconnect.
        db_data[:reconnect] = true

        block = Proc.new  if block_given?

        OverSIP::SystemCallbacks.on_started do
          log_info "Adding MySQL connection pool (name: #{name.inspect}, size: #{pool_size})..."
          @pools[name] = ::EM::Synchrony::ConnectionPool.new(size: pool_size) do
            conn = ::Mysql2::EM::Client.new(db_data)
            block.call(conn)  if block
            conn
          end
        end
      end  # def self.add_pool

      def self.pool name
        pool = @pools[name]
        raise ::ArgumentError, "no pool with `name' #{name.inspect}"  unless pool
        pool
      end

    end  # module Mysql

  end
end
