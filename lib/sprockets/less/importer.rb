module Sprockets  
  module Less  
    class Importer
      # TODO: override `tree.Import` to inject our own import resolution
      # logic and .push() into its `imports` argument.
      # See less/tree/import.js

      # Reference to the Sprockets context
      attr_reader :context
      
      IMPORT_SCANNER = /^\s*@import\s*['"]([^'"]+)['"]\s*;/.freeze

      def initialize(context)
        @context = context
      end

      # Finds an asset from the given path. This is where
      # we make Sprockets behave like Less, and import partial
      # style paths.
      def resolve(path, base_path)
        possible_files(path, base_path).each do |file|
          context.resolve(file) { |found| return found if context.asset_requirable?(found) }
        end

        nil
      end
      
      # Returns all of the possible paths (including partial variations)
      # to attempt to resolve with the given path.
      def possible_files(path, base_path)
        path      = Pathname.new(path)
        base_path = Pathname.new(base_path).dirname
        root_path = Pathname.new(context.root_path)
        paths     = [ path, partialize_path(path) ]

        # Add the relative path from the root, if necessary
        if path.relative? && base_path != root_path && path.to_s !~ /\A\.\//
          relative_path = base_path.relative_path_from(root_path).join path
          
          paths.unshift(relative_path, partialize_path(relative_path))
        end

        paths.compact
      end
      
      # Returns the partialized version of the given path.
      # Returns nil if the path is already to a partial.
      def partialize_path(path)
        if path.basename.to_s !~ /\A_/
          Pathname.new path.to_s.sub(/([^\/]+)\Z/, '_\1')
        end
      end
      
      # Returns the syntax of the given path.
      def syntax(path)
        path.to_s.include?('.css') ? :css : :less
      end
      
      # Returns the string to be passed to the Less engine. We use
      # Sprockets to process the file, but we remove any Less processors
      # because we need to let the Sass::Engine handle that.
      def evaluate(path)
        processors = context.environment.attributes_for(path).processors.dup
        processors.delete_if { |processor| processor < Tilt::LessTemplate }
        context.evaluate(path, :processors => processors)
      end

      # Tests if a path will make the import directive be passed as is.
      def passthrough?(pathname)
        pathname.to_s.end_with?('.css')
      end
      
      # Assemble dependencies for the context
      def process_dependencies(data)
        import_paths = data.scan(IMPORT_SCANNER).flatten.compact.uniq
        import_paths.each do |path|
          pathname = begin
                       #TODO: use resolve to partialize paths
                       context.resolve(path)
                     rescue Sprockets::FileNotFound
                       nil
                     end
          
          unless pathname.nil? || passthrough?(pathname)
            # mark dependency in Sprockets context
            context.depend_on(path)
            # recurse for more dependencies
            process_dependencies File.read(pathname)
          end
        end
      end
      
    end
  end
end