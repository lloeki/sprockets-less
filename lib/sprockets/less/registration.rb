# frozen_string_literal: true
module Sprockets
  module Less
    # class useful for registering engines, tranformers, preprocessors and conpressors for sprockets
    # depending on the version of sprockets
    class Registration
      attr_reader :klass, :sprockets_version, :registration_instance

      def initialize(klass)
        @klass = klass
        @sprockets_version = Sprockets::Less::Utils.version_of_sprockets
        @registration_instance = self
      end

      def run
        require_libraries
        case @sprockets_version
          when 2...3
            register_sprockets_legacy
          when 3...4
            register_sprockets_v3
          when 4...5
            register_sprockets_v4
          else
            raise "Version #{Sprockets::Less::Utils.full_version_of_sprockets} is not supported"
        end
      end

      def require_libraries
        require_standard_libraries
        require 'sprockets/less/functions'
      end

    private

      def require_standard_libraries(version = @sprockets_version)
        %w(cache_store functions importer less_template).each do |filename|
          begin
            require "sprockets/less/v#{version}/#{filename}"
          rescue LoadError; end
        end
      end


      def register_sprockets_v3_common
        _register_mime_types(mime_type:  "application/less+ruby", extensions: [".less.erb", ".css.less.erb"])
        register_bundle_metadata_reducer 'text/css', :less_dependencies, Set.new, :+
      end

      def register_sprockets_v4
        register_sprockets_v3_common
        _register_mime_types(mime_type:  "text/less", extensions: [".less", ".css.less"])
        _register_transformers(from: "application/less+ruby", to: "text/less", klass: Sprockets::ERBProcessor)
        _register_v4_preprocessors(DirectiveProcessor.new(comments: ["//", ["/*", "*/"]]) => ['text/less'])
        _register_v4_preprocessors(Sprockets::Less::V4::LessTemplate => ['text/less'])
        _register_transformers(from: 'text/less', to: 'text/css', klass: Sprockets::Less::V4::LessTemplate)
      end

      def register_sprockets_v3
        register_sprockets_v3_common
        _register_transformers(from: 'application/less+ruby', to: 'text/css', klass: Sprockets::ERBProcessor)
        _register_engines('.less' => Sprockets::Less::V3::LessTemplate)
      end

      def register_sprockets_legacy
        _register_engines('.less' => Sprockets::Less::V2::LessTemplate)
      end

      def _register_engines(hash)
        hash.each do |key, value|
          args = [key, value]
          args << { mime_type: 'text/css', silence_deprecation: true } if sprockets_version >= 3
          register_engine(*args)
        end
      end

      def _register_mime_types(*mime_types)
        mime_types.each do |mime_data|
          register_mime_type(mime_data[:mime_type], extensions: mime_data[:extensions])
        end
      end

      def _register_compressors(*compressors)
        compressors.each do |compressor|
          register_compressor(compressor[:mime_type], compressor[:name], compressor[:klass])
        end
      end

      def _register_transformers(*tranformers)
        tranformers.each do |tranformer|
          register_transformer(tranformer[:from], tranformer[:to], tranformer[:klass])
        end
      end

      def _register_v4_preprocessors(hash)
        hash.each do |key, value|
          value.each do |mime|
            register_preprocessor(mime, key)
          end
        end
      end

      def method_missing(sym, *args, &block)
        @klass.public_send(sym, *args, &block) || super
      end

      def respond_to_missing?(method_name, include_private = nil)
        include_private = include_private.blank? ? true : include_private
        @klass.public_methods.include?(method_name) || super(method_name, include_private)
      end
    end
  end
end
