# frozen_string_literal: true
module Sprockets
  module Less
    module V2
      # Preprocessor for Less files
      class LessTemplate
        VERSION = '1'

        def self.default_mime_type
          'text/css'
        end

        # Internal: Defines default Less syntax to use. Exposed so the ScssProcessor
        # may override it.
        def self.syntax
          :less
        end

        # Public: Return singleton instance with default options.
        #
        # Returns LessTemplate object.
        def self.instance
          @instance ||= new
        end

        def self.call(input)
          instance.call(input)
        end

        def self.cache_key
          instance.cache_key
        end

        attr_reader :cache_key, :filename, :source, :context, :options

        def initialize(options = {}, &block)
          @default_options = { default_encoding: Encoding.default_external || 'utf-8' }
          initialize_engine
          if options.is_a?(Hash)
            instantiate_with_options(options, &block)
          else
            instantiate_with_filename_and_source(options, &block)
          end
        end

        def instantiate_with_filename_and_source(options)
          @filename = options
          @source = block_given? ? yield : nil
          @options = @default_options
          @cache_version = VERSION
          @cache_key = "#{self.class.name}:#{::Less::VERSION}:#{VERSION}:#{Sprockets::Less::Utils.digest(options)}"
          @functions = Module.new do
            include Sprockets::Helpers if defined?(Sprockets::Helpers)
            include Sprockets::Less::Utils.get_class_by_version('Functions')
          end
        end

        def instantiate_with_options(options, &block)
          @cache_version = options[:cache_version] || VERSION
          @cache_key = "#{self.class.name}:#{::Less::VERSION}:#{@cache_version}:#{Sprockets::Less::Utils.digest(options)}"
          @filename = options[:filename]
          @source = options[:data]
          @options = options.merge(@default_options)
          @importer_class = options[:importer]
          @less_config = options[:less_config] || {}
          @input = options
          @functions = Module.new do
            include Sprockets::Helpers if defined?(Sprockets::Helpers)
            include Sprockets::Less::Utils.get_class_by_version('Functions')
            include options[:functions] if options[:functions]
            class_eval(&block) if block_given?
          end
        end

        @less_functions_initialized = false
        class << self
          attr_accessor :less_functions_initialized
          alias less_functions_initialized? less_functions_initialized
          # Templates are initialized once the functions are added.
          def engine_initialized?
            less_functions_initialized?
          end
        end

        # Add the Less functions if they haven't already been added.
        def initialize_engine
          return if self.class.engine_initialized?

          if Sprockets::Less.add_less_functions
            begin
              require 'sprockets/helpers'
              require 'sprockets/less/functions'
              self.class.less_functions_initialized = true
            rescue LoadError; end
          end
        end

        def call(input)
          @input = input
          @filename = input[:filename]
          @source   = input[:data]
          @context  = input[:environment].context_class.new(input)
          run
        end

        def render(context, _empty_hash_wtf)
          @context = context
          run
        end


        def less_engine(data, less_options, css_options)
          ::Less.Parser['sprockets_context'] = context
          parser = ::Less::Parser.new(less_options)
          parser.tree.extend_js @functions
          engine = parser.parse(data)
          engine.to_css(css_options)
        end

        def run
          css = retrieve_from_cache_store
          if css.nil?
            data = Sprockets::Less::Utils.read_file_binary(filename, options)
            new_data, dependencies = process_dependencies(data)

            css  = less_engine(new_data, less_options, css_options)
            store_into_cache_store(css)

            less_dependencies = Set.new([filename])
            if context.respond_to?(:metadata)
              dependencies.map do |dependency|
                less_dependencies << dependency.to_s
                context.metadata[:dependencies] << Sprockets::URIUtils.build_file_digest_uri(dependency.to_s)
              end
              context.metadata.merge(data: css, less_dependencies: less_dependencies)
            else
              css
            end
          else
            css
          end

        rescue => e
          # Annotates exception message with parse line number
          raise [e, e.backtrace].join("\n")
        end

        def css_options
          css_keys = [:compress, :optimization, :silent, :color]
          Hash[less_options.to_enum.to_a.select{|k, _| css_keys.include? k}]
        end


        def process_dependencies(data)
          fetch_importer_class.fetch_all_dependencies(data, filename, less_options, css_options)
        end

        def merge_less_options(options, other_options)
          if (load_paths = options[:load_paths]) && (other_paths = other_options[:load_paths])
            other_options[:load_paths] = other_paths + load_paths
          end
          options = options.merge(other_options)
          options[:load_paths] = options[:load_paths].is_a?(Array) ? options[:load_paths] : []

          if (load_paths = options[:paths]) && (other_paths = other_options[:paths])
            options[:load_paths] = options[:load_paths]+ other_paths + load_paths
          end
          options[:load_paths] = options[:load_paths].concat(context.environment.paths)
          options
        end

        def default_less_config
          @default_less_config ||= Sprockets::Less.options.dup
        end

        def default_less_options
          default_less_config[:load_paths] =  default_less_config[:load_paths].is_a?(Array) ? default_less_config[:load_paths] : []
          default_less_config[:load_paths] = default_less_config[:load_paths].concat(default_less_config[:paths]) if default_less_config[:paths].is_a?(Array)
          less =  default_less_config
          less = merge_less_options(less.dup, @less_config) if defined?(@less_config) && @less_config.is_a?(Hash)
          less
        end

        def cache_sha_filename
          Sprockets::Less::Utils.digest(Sprockets::Less::Utils.read_file_binary(filename, options))
        end

        def retrieve_from_cache_store
          return if less_options[:cache] == false || less_options[:cache_store].nil?
          less_options[:cache_store]._retrieve(@cache_key, @cache_version,  cache_sha_filename)
        end

        def store_into_cache_store(data)
          return if less_options[:cache] == false || less_options[:cache_store].nil?
          less_options[:cache_store]._store(@cache_key, @cache_version,  cache_sha_filename, data)
        end

        def build_cache_store(context)
          return nil if context.environment.cache.nil?
          custom_cache_store(context.environment)
        end

        def custom_cache_store(*args)
          Sprockets::Less::V2::CacheStore.new(*args)
        end

        # Allow the use of custom Less importers, making sure the
        # custom importer is a `Sprockets::Less::Importer`
        def fetch_importer_class
          if defined?(@importer_class) && !@importer_class.nil?
            @importer_class
          elsif default_less_options.key?(:importer) && default_less_options[:importer].is_a?(Importer)
            default_less_options[:importer]
          else
            custom_importer_class
          end
        end

        def custom_importer_class
          @custom_importer_class ||= Sprockets::Less::V2::Importer.new
        end

        def fetch_sprockets_options
          {
            context: context,
            environment: context.environment,
            load_paths: context.environment.paths + default_less_options[:load_paths],
            dependencies: context.respond_to?(:metadata) ? context.metadata[:dependencies] : []
          }
        end

        def less_options
          importer = fetch_importer_class
          sprockets_options = fetch_sprockets_options

          less = merge_less_options(default_less_options, options).merge(
          filename: filename,
          line: 1,
          syntax: self.class.syntax,
          load_paths: sprockets_options[:load_paths],
          cache: true,
          cache_store: build_cache_store(context),
          importer: importer,
          custom: { sprockets_context: context },
          sprockets: sprockets_options
          )
          less
        end
      end
    end
  end
end
