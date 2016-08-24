module Less

  # Wrapper for the `tree` JavaScript module.
  #
  # This is not to be confused with Less::Parser::Tree, as Less uses that
  # to wrap the AST (which is actually a tree.RuleSet) resulting from parsing
  class Tree
    attr_reader :sprockets_context

    def initialize(options)
      @tree = Less.instance_eval { @loader.require('less/tree') }
    end

    # Adds all of a module's public instance methods as Less functions
    def extend_js(mod)
      extend mod
      mod.public_instance_methods.each do |method_name|
        add_function(sym_to_css(method_name)) { |tree, cxt|
          send method_name.to_sym, unquote(cxt.toCSS())
        }
      end
    end

    #private

    # Transforms a css function name string to a (method) symbol
    def css_to_sym(str)
      str.gsub('-','_').to_sym
    end

    # Transforms a method symbol to a css function name string
    def sym_to_css(sym)
      sym.to_sym.to_s.gsub('_', '-')
    end

    # Removes quotes
    def unquote(str)
      s = str.to_s.strip
      s.gsub!(/["']+/, '')
      s
    end

    # Creates a JavaScript anonymous function from a Ruby block
    def anonymous_function(block)
      lambda do |*args|
        # args: (this, node) v8 >= 0.10, otherwise (node)
        raise ArgumentError, "missing node" if args.empty?
        options = args.last.is_a?(::Hash) ? args.pop : {}
        @tree[:Anonymous].new block.call(@tree, args.last, options)
      end
    end

    # Access to the Less JavaScript function object
    def functions
      @tree['functions']
    end

    # Injects a Ruby method into the JavaScript Less
    def add_function(name, &block)
      functions[name] = anonymous_function(block)
    end

  end
end

::Less::Parser.class_eval do
  attr_reader :tree


  # Override the parser's initialization to improve Less `tree`
  # with sprockets awareness
  alias_method :initialize_without_tree, :initialize
  alias_method :original_parse, :parse

  def initialize(options={})
    initialize_without_tree(options)
    @tree = Less::Tree.new(options)
  end

  def string_to_hash(string, arr_sep=',', key_sep=':')
    array = string.split(arr_sep)
    hash = {}

    array.each do |e|
      key_value = e.split(key_sep)
      hash[key_value[0].strip.to_sym] = key_value[1].strip
    end

    return hash
  end

  def matches str, pattern
   arr = []
   offset = 0
   while (offset < str.size && (m = str.match pattern))
       offset = m.offset(0).first
       arr << { match: m, index: offset } unless m.nil?
       str = str[(offset + 1)..-1]
   end
   arr.uniq {|hash| hash[:match] }
 end

  def parse_functions(less, options = {})
    @tree.functions.keys.each do |function_name|
      next unless @tree.respond_to?(@tree.css_to_sym(function_name))
      function_regex =  /#{function_name}\(([^\)]*)\)/
      function_data = matches(less, function_regex)
      function_data.each do |hash|
        captures = hash[:match].captures.map {|a| a.split(',').map {|b| b.gsub(/["']+/, '') } }.flatten.compact.uniq
        params = []
        captures.each do |param|
            if param.include?("@{")
             variables = param.scan(/@\{([a-zA-Z0-9\-\_]+)\}/).flatten.compact.uniq
             variables.each do |variable|
              variable_value = less[1.. hash[:index]].scan(/@#{variable}\:\s+["']{1}([^"']+)["']{1}/).flatten.compact.uniq.last.to_s
               param = param.gsub(/@\{#{variable}\}/, variable_value)
              end
            end
            param = param.gsub(/@(?=\w+)/, '')
            if param.include?(':')
              options.merge!(string_to_hash(param))
            else
              params << param
            end
        end
        params << options  if options.keys.size > 0
        begin
        css = @tree.send(@tree.css_to_sym(function_name), *params)
        rescue =>  e
          raise [e, function_name, params, less].inspect
        end
        less.gsub!(function_regex, css)
      end
    end
    less
  end

  def parse(less)
    uri_rx = /\s+url\((.*)\)/
    urls = less.scan(uri_rx).flatten.compact.uniq
    if urls.size > 0
      urls.each do |url|
        original_url = url.dup
        url = parse_functions(url, from_url: true)
        less.gsub!(original_url, url)
      end
    end
    parse_functions(less)
    original_parse(less)
  end
end
