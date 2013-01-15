module OverSIP
  module Modules

    module Mysql
      module Version
        MAJOR = 0
        MINOR = 1
        TINY  = 1
        DEVEL = nil  # Set to nil for stable releases.
      end

      VERSION = [Version::MAJOR, Version::MINOR, Version::TINY].join(".")
      VERSION << ".#{Version::DEVEL}"  if Version::DEVEL
    end

  end
end
