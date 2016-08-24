require 'sprockets'
require 'sprockets/less/version'
require 'sprockets/less/utils'
require 'sprockets/less/registration'

require 'less'

require 'cgi'
require 'json'
require 'pathname'

module Sprockets
  module Less

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


  begin
    require 'sprockets/directive_processor'
    require 'sprockets/digest_utils'
    require 'sprockets/engines'
  rescue LoadError; end

  if Sprockets::Less::Utils.version_of_sprockets >= 3
    # We need this only for Sprockets > 3 in order to be able to register anything.
    # For Sprockets 2.x , although the file and the module name exist,
    # they can't be used because it will give errors about undefined methods, because this is included only on Sprockets::Base
    # and in order to use them we would have to subclass it and define methods to expire cache and other methods for registration ,
    # which are not needed since Sprockets already  knows about that using the environment instead internally
    require 'sprockets/processing'
    extend Sprockets::Processing
  end

  registration = Sprockets::Less::Registration.new(self)
  registration.run
end
