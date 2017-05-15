# frozen_string_literal: true
require_relative '../v2/less_template'
module Sprockets
  module Less
    module V3
      # Preprocessor for SASS files
      class LessTemplate < Sprockets::Less::V2::LessTemplate
        def build_cache_store(context)
          return nil if context.environment.cache.nil?
          cache = @input[:cache]
          version = @cache_version
          custom_cache_store(cache, version)
        end

        def custom_cache_store(*args)
          Sprockets::Less::V3::CacheStore.new(*args)
        end

        # Allow the use of custom SASS importers, making sure the
        # custom importer is a `Sprockets::Sass::Importer`
        def fetch_importer_class
          if defined?(@importer_class) && !@importer_class.nil?
            @importer_class
          elsif default_less_options.key?(:importer) && default_less_options[:importer].is_a?(Importer)
            default_less_options[:importer]
          else
            Sprockets::Less::V3::Importer.new
          end
        end
      end
    end
  end
end
