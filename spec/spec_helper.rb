require 'rubygems'
require 'bundler/setup'
require 'sprockets'
require 'sprockets-less'
require 'sprockets-helpers'
require 'test_construct'


RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec
  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec

  config.include RSpec::Matchers
  config.include TestConstruct::Helpers
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }


def write_asset(filename, contents, mtime = nil)
  mtime ||= [Time.now.to_i, File.stat(filename).mtime.to_i].max + 1
  File.open(filename, 'w') do |f|
    f.write(contents)
  end
  if Sprockets::Less::Utils.version_of_sprockets >= 3
    File.utime(mtime, mtime, filename)
  else
    mtime = Time.now + 1
    filename.utime mtime, mtime
  end
end
