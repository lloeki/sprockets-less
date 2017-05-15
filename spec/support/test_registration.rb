module Sprockets
  module Less
    class TestRegistration < Sprockets::Less::Registration

      def register_engines(hash)
        _register_engines(hash)
      end

    end
  end
end
