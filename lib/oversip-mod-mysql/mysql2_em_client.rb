module Mysql2
  module EM
    class Client
      # Allow the aquery() method even if 'em-synchrony' is not loaded.
      alias :aquery :query
    end
  end
end
