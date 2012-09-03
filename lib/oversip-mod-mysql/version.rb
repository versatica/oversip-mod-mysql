module OverSIP
  module Modules

    module Mysql
      module Version
        MAJOR = 0
        MINOR = 0
        TINY  = 1
        DEVEL = "beta1"  # Set to nil for stable releases.
      end

      VERSION = [Version::MAJOR, Version::MINOR, Version::TINY].join(".")
    end

  end
end
