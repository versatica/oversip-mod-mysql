require "oversip-mod-mysql/version.rb"
require "mysql2/em"


module OverSIP
  module Modules

    module Mysql

      extend ::OverSIP::Logger

      DEFAULT_POOL_SIZE = 10
      DEFAULT_SYNCHRONY = false

      @log_id = "mod mysql"
      @pools = {}

      def self.add_pool options, db_data
        raise ::ArgumentError, "`options' must be a Hash"  unless options.is_a? ::Hash
        raise ::ArgumentError, "`db_data' must be a Hash"  unless db_data.is_a? ::Hash

        name, pool_size, synchrony = options.values_at(:name, :pool_size, :synchrony)
        pool_size ||= DEFAULT_POOL_SIZE
        synchrony ||= DEFAULT_SYNCHRONY

        raise ::ArgumentError, "`options[:name]' must be a Symbol"  unless name.is_a? ::Symbol
        raise ::ArgumentError, "`options[:pool_size]' must be a positive Fixnum"  unless pool_size.is_a? ::Fixnum and pool_size > 0

        # Use em-synchrony for serial coding.
        if synchrony
          begin
            require "em-synchrony"
            require "em-synchrony/mysql2"
          rescue ::LoadError
            OverSIP::Launcher.fatal "em-synchrony not installed: gem install em-synchrony"
          end

          OverSIP::SystemCallbacks.on_started do
            log_system_info "Adding a sync pool with name #{name.inspect}..."
            @pools[name] = ::EM::Synchrony::ConnectionPool.new(size: pool_size) do
              ::Mysql2::EM::Client.new(db_data)
            end
          end

        # Don't use em-synchrony but pure callbacks.
        else
          OverSIP::SystemCallbacks.on_started do
            log_system_info "Adding an async pool with name #{name.inspect}..."
            pool = @pools[name] = ::EM::Pool.new
            pool_size.times do
              pool.add ::Mysql2::EM::Client.new(db_data)
            end
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
