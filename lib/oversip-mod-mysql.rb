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

        # Avoid the hash to be modified internally.
        options = options.clone
        # Delete options not existing in mysql2.
        pool_name = options.delete(:pool_name)
        pool_size = options.delete(:pool_size) || DEFAULT_POOL_SIZE

        raise ::ArgumentError, "`options[:pool_name]' must be a Symbol"  unless pool_name.is_a? ::Symbol
        raise ::ArgumentError, "`options[:pool_size]' must be a positive Fixnum"  unless pool_size.is_a? ::Fixnum and pool_size > 0

        block = ::Proc.new  if block_given?

        ::OverSIP::SystemCallbacks.on_started do
          log_info "Adding MySQL connection pool (name: #{pool_name.inspect}, size: #{pool_size})..."
          @pools[pool_name] = Pool.new pool_size, options, block
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


      class Pool

        def initialize pool_size, options, block
          @em_synchrony_connectionpool = ::EM::Synchrony::ConnectionPool.new(size: pool_size) do
            # Avoid the hash to be modified internally.
            options = options.clone
            # Force DB autoreconnect.
            options[:reconnect] = true

            conn = ::Mysql2::EM::Client.new(options)

            # Call the given block by passing conn as argument.
            block.call(conn)  if block
            conn
          end
        end

        def method_missing method, *args, &blk
          @em_synchrony_connectionpool.__send__ method, *args, &blk
        end

        def query *args, &blk
          # If we are not in the OverSIP Root Fiber then do nothing special.
          if ::Fiber.current != ::OverSIP.root_fiber
            @em_synchrony_connectionpool.__send__ :query, *args, &blk
          # Otherwise run the query within a new Fiber.
          else
            ::Fiber.new do
              @em_synchrony_connectionpool.__send__ :query, *args, &blk
            end.resume
          end
        end

      end  # class Pool

    end  # module Mysql

  end
end
