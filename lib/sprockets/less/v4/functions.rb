# frozen_string_literal: true
require_relative '../v3/functions'
module Sprockets
  module Less
    module V4
      # Module used to inject helpers into SASS engine
      module Functions
        include Sprockets::Less::V3::Functions
      end
    end
  end
end
