# frozen_string_literal: true
require_relative '../v3/less_template'
module Sprockets
  module Less
    module V4
      # Preprocessor for SASS files
      class LessTemplate < Sprockets::Less::V3::LessTemplate
        # This is removed
        # def self.default_mime_type
        #   "text/#{syntax}"
        # end
        #
        def self.syntax
          :less
        end

        def custom_cache_store(*args)
          Sprockets::Less::V4::CacheStore.new(*args)
        end

        def custom_importer_class(*_args)
          Sprockets::Less::V4::Importer.new
        end
      end
    end
  end
end
