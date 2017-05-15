# frozen_string_literal: true

module Sprockets
  module Less
    module V2
      # class used for importing files from SCCS and SASS files
      class Importer
        GLOB = /\*|\[.+\]/
        IMPORT_SCANNER = /^\s*@import\s*['"]([^'"]+)['"]\s*;/.freeze

        def dependencies
          @dependencies ||= []
        end

        def context
          @context
        end

        def fetch_import_paths(data)
          data.scan(Regexp.union(IMPORT_SCANNER, GLOB)).flatten.compact.uniq
        end

        def fetch_all_dependencies(data, filename, less_options, css_options)
          process_dependencies(data, filename, less_options, css_options)
          [data, dependencies]
        end

        #Assemble dependencies for the context
        def process_dependencies(data, filename, less_options, css_options)
          @context = context = less_options[:custom][:sprockets_context]

          final_css = ''.dup
          import_paths = fetch_import_paths(data)
          import_paths.each do |path|
            css = find_relative(path, filename, less_options, css_options)
            data.gsub!(/^\s*@import\s*['"]#{Regexp.escape(path)}['"]\s*;/, css)
            final_css << css
          end
          final_css
        end


        protected

        def find_relative(path, base_path, less_options, css_options)
          css = nil
          if path.to_s =~ GLOB
            css = engine_from_glob(path, base_path, less_options, css_options)
          else
            css = engine_from_path(path, base_path, less_options, css_options)
          end
          css.to_s
        end

        # Create a Sass::Engine from the given path.
        def engine_from_path(path, base_path, less_options, css_options)
          context = less_options[:custom][:sprockets_context]
          (pathname = resolve(context, path, base_path))  || (return nil)
          context.depend_on pathname
          dependencies << pathname
          data_to_parse = evaluate(context, pathname)
          import_paths =  fetch_import_paths(data_to_parse)
          if import_paths.size > 0
            import_paths.each do |import_path|
              css = find_relative(import_path, pathname, less_options, css_options)
              data_to_parse.gsub!(/^\s*@import\s*['"]#{Regexp.escape(import_path)}['"]\s*;/, css)
            end
          end
          begin
            css = less_engine(data_to_parse, pathname, context,  less_options, css_options)
          rescue => e
            css = e.message =~ /is undefined/ ? data_to_parse : nil
          end
          css.nil? || css.empty? ? data_to_parse : css
        end


        def less_engine(data, filename, context,  less_options, css_options)
          if ::Less.const_defined? :Engine
            engine = ::Less::Engine.new(data)
          else
            parser  = ::Less::Parser.new(less_options.merge(
            filename: filename.to_s,
            syntax: syntax,
            importer: self,
            custom: { sprockets_context: context }
            ))
            engine = parser.parse(data)
          end
          engine.to_css(css_options)
        end

        # Create a Sass::Engine that will handle importing
        # a glob of files.
        def engine_from_glob(glob, base_path, less_options, css_options)
          context = less_options[:custom][:sprockets_context]
          engine_imports = resolve_glob(context, glob, base_path).reduce(''.dup) do |imports, path|
            context.depend_on path
            dependencies << path
            relative_path = path.relative_path_from Pathname.new(base_path).dirname
            imports << find_relative(relative_path, base_path, less_options, css_options)
          end
          return nil if engine_imports.empty?
          css = less_engine(engine_imports, base_path, context, less_options, css_options)
          css.nil? || css.empty? ? engine_imports : css
        end

        # Finds an asset from the given path. This is where
        # we make Sprockets behave like Sass, and import partial
        # style paths.
        def resolve(context, path, base_path)
          paths, _root_path = possible_files(context, path, base_path)
          paths.each do |file|
            context.resolve(file.to_s) do |found|
              return found if context.asset_requirable?(found)
            end
          end
          nil
        end

        # Finds all of the assets using the given glob.
        def resolve_glob(context, glob, base_path)
          base_path      = Pathname.new(base_path)
          path_with_glob = base_path.dirname.join(glob).to_s

          Pathname.glob(path_with_glob).sort.select do |path|
            asset_requirable = context.asset_requirable?(path)
            path != context.pathname && asset_requirable
          end
        end

        def context_root_path(context)
          Pathname.new(context.root_path)
        end

        def context_load_pathnames(context)
          context.environment.paths.map { |p| Pathname.new(p) }
        end

        # Returns all of the possible paths (including partial variations)
        # to attempt to resolve with the given path.
        def possible_files(context, path, base_path)
          path      = Pathname.new(path)
          base_path = Pathname.new(base_path).dirname
          partial_path = partialize_path(path)
          additional_paths = [
            Pathname.new("#{path}.css"),
            Pathname.new("#{partial_path}.css"),
            Pathname.new("#{path}.css.#{syntax}"),
            Pathname.new("#{partial_path}.css.#{syntax}"),
            Pathname.new("#{path}.css.#{syntax}.erb"),
            Pathname.new("#{partial_path}.css.#{syntax}.erb"),
            Pathname.new("#{path}.#{syntax}.erb"),
            Pathname.new("#{partial_path}.#{syntax}.erb")
          ]
          paths = additional_paths.concat([path, partial_path])

          # Find base_path's root
          paths, root_path = add_root_to_possible_files(context, base_path, path, paths)
          [paths.compact, root_path]
        end

        def add_root_to_possible_files(context, base_path, path, paths)
          env_root_paths = context_load_pathnames(context)
          root_path = env_root_paths.find do |env_root_path|
            base_path.to_s.start_with?(env_root_path.to_s)
          end
          root_path ||= context_root_path(context)
          # Add the relative path from the root, if necessary
          if path.relative? && base_path != root_path
            relative_path = base_path.relative_path_from(root_path).join path
            paths.unshift(relative_path, partialize_path(relative_path))
          end
          [paths, root_path]
        end

        # Returns the partialized version of the given path.
        # Returns nil if the path is already to a partial.
        def partialize_path(path)
          return unless path.basename.to_s !~ /\A_/
          Pathname.new path.to_s.sub(/([^\/]+)\Z/, '_\1')
        end

        # Returns the Sass syntax of the given path.
        def syntax
          :less
        end

        def syntax_mime_type
          'text/css'
        end

        def filtered_processor_classes
          classes = [Sprockets::Less::Utils.get_class_by_version('LessTemplate')]
          classes << Tilt::LessTemplate if defined?(Tilt::LessTemplate)
          classes
        end

        def content_type_of_path(context, path)
          attributes = context.environment.attributes_for(path)
          content_type = attributes.content_type
          [content_type, attributes]
        end

        def get_context_preprocessors(context, content_type)
          context.environment.preprocessors(content_type)
        end

        def get_context_transformers(_context, _content_type, _path)
          []
        end

        def get_engines_from_attributes(context, attributes)
          attributes.engines
        end
        
        def get_all_processors_for_evaluate(context, content_type, attributes, path)
          engines = get_engines_from_attributes(context, attributes)
          preprocessors = get_context_preprocessors(context, content_type)
          additional_transformers = get_context_transformers(context, content_type, path)
          additional_transformers.reverse + preprocessors + engines.reverse
        end

        def filter_all_processors(processors)
          processors.delete_if do |processor|
            filtered_processor_classes.include?(processor) || filtered_processor_classes.any? do |filtered_processor|
              !processor.is_a?(Proc) && processor < filtered_processor
            end
          end
        end

        def evaluate_path_from_context(context, path, processors)
          context.evaluate(path, processors: processors)
        end

        # Returns the string to be passed to the Sass engine. We use
        # Sprockets to process the file, but we remove any Sass processors
        # because we need to let the Sass::Engine handle that.
        def evaluate(context, path)
          content_type, attributes = content_type_of_path(context, path)
          processors = get_all_processors_for_evaluate(context, content_type, attributes, path)
          filter_all_processors(processors)
          evaluate_path_from_context(context, path, processors)
        end


      end
    end
  end
end
