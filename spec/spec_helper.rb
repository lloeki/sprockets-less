require 'sprockets'
require 'sprockets-less'
require 'sprockets-helpers'
require 'test_construct'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include TestConstruct::Helpers
end
