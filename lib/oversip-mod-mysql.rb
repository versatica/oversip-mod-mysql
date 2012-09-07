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

      def self.add_pool options
        raise ::ArgumentError, "`options' must be a Hash"  unless options.is_a? ::Hash

        pool_name = options.delete(:pool_name)
        pool_size = options.delete(:pool_size) || DEFAULT_POOL_SIZE

        raise ::ArgumentError, "`options[:pool_name]' must be a Symbol"  unless pool_name.is_a? ::Symbol
        raise ::ArgumentError, "`options[:pool_size]' must be a positive Fixnum"  unless pool_size.is_a? ::Fixnum and pool_size > 0

        # Forcing DB autoreconnect.
        options[:reconnect] = true

        block = Proc.new  if block_given?

        OverSIP::SystemCallbacks.on_started do
          log_info "Adding MySQL connection pool (name: #{pool_name.inspect}, size: #{pool_size})..."
          @pools[pool_name] = ::EM::Synchrony::ConnectionPool.new(size: pool_size) do
            conn = ::Mysql2::EM::Client.new(options)
            block.call(conn)  if block
            conn
          end
        end
      end  # def self.add_pool

      def self.pool pool_name
        pool = @pools[pool_name]
        raise ::ArgumentError, "no pool with `name' #{pool_name.inspect}"  unless pool
        pool
      end
      class << self
        alias :get_pool :pool
      end

    end  # module Mysql

  end
end
