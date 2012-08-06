require 'tilt'

module Sprockets  
  module Less  
    class LessTemplate < Tilt::LessTemplate
      self.default_mime_type = 'text/css'

      # A reference to the current Sprockets context
      attr_reader :context
      
      # Templates are initialized once the functions are added.
      def self.engine_initialized?
        super && (!Less.add_less_functions || defined?(Functions))
      end

      # Add the Less functions if they haven't already been added.
      def initialize_engine
        super unless self.class.superclass.engine_initialized?
        
        if Less.add_less_functions
          require 'sprockets/less/functions'
        end
      end

      # Define the expected syntax for the template
      def syntax
        :less
      end

      # See `Tilt::Template#prepare`.
      def prepare
        @context = nil
        @output = nil
      end
      
      # See `Tilt::Template#evaluate`.
      def evaluate(context, locals, &block)
        @output ||= begin
          @context = context
          process_dependencies less_options
          parser = ::Less::Parser.new less_options
          tree = parser.parse(data)
          tree.to_css css_options
        end
      end
      
      protected

      def process_dependencies options
        options[:importer].process_dependencies data
      end

      # Returns a Sprockets-aware cache store.
      def cache_store
        return nil if context.environment.cache.nil?

        CacheStore.new context.environment
      end

      # A reference to the custom Less importer, `Sprockets::Less::Importer`.
      def importer
        Importer.new context
      end

      # Assemble the options for the Less parser
      def less_options
        new_options = merge_less_options(global_less_options, options)
        merge_less_options(new_options, default_less_options)
      end

      # Extract options for CSS output
      def css_options
        css_keys = [:compress, :optimization, :silent, :color]
        Hash[less_options.to_enum.to_a.select{|k, _| css_keys.include? k}]
      end

      # Get global Less options
      def global_less_options
        Sprockets::Less.options.dup
      end

      def default_less_options
        {
          :filename => eval_file,
          :line => line,
          :paths => context.environment.paths,
          #:syntax => syntax,
          #:cache_store => cache_store,
          :importer => importer
        }
      end

      # Merges two sets of Less parser options, prepending
      # the `:paths` instead of clobbering them.
      def merge_less_options(options, other_options)
        if (load_paths = options[:paths]) && (other_paths = other_options[:paths])
          other_options[:paths] = other_paths + load_paths
        end
        options.merge other_options
      end
    end    
  end
end
