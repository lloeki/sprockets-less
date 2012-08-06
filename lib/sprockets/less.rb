require 'sprockets/less/version'
require 'sprockets/less/template'
require 'sprockets/engines'

module Sprockets
  module Less
    autoload :Importer,   'sprockets/less/importer'

    class << self
      # Global configuration for `Less::Parser` instances
      attr_accessor :options

      # When false, the asset path helper provided by
      # `sprockets-helpers` will not be added as Less functions.
      # `true` by default.
      attr_accessor :add_less_functions
    end

    @options = {}
    @add_less_functions = true
  end

  register_engine '.less', Less::LessTemplate
end