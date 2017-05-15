# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sprockets/less/version"
require 'date'
Gem::Specification.new do |s|
  s.name        = "sprockets-less"
  s.version     = Sprockets::Less::VERSION
  s.authors     = ["Loic Nageleisen"]
  s.email       = ["loic.nageleisen@gmail.com"]
  s.homepage    = "http://github.com/lloeki/sprockets-less"
  s.summary     = %q{The dynamic stylesheet language for the Sprockets asset pipeline.}
  s.description = %q{The dynamic stylesheet language for the Sprockets asset pipeline.}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # usually the license needs to be specified in gemspec also as a standard
  s.licenses = ['MIT']

  # This is needed so that on rubygems.org we can see the actual date
  # of the published version due to changes in Rubygems repo over the last year(2015 - 2016)
  s.date = Date.today

  # usually the platform needs to be specified also, to avoid people trying to install this gem on wrong platform
  s.platform = Gem::Platform::RUBY

  s.required_ruby_version = '>= 2.0'
  s.required_rubygems_version = '>= 2.0'
  s.metadata = {
    'source_url' => s.homepage,
    'issue_tracker' => "#{s.homepage}/issues"
  }

  s.add_dependency 'less', '~> 2.6'

  s.add_development_dependency 'sprockets-helpers', '~> 1.0'
  s.add_development_dependency 'yui-compressor'

  s.add_development_dependency 'rspec',             '~> 3.5'
  s.add_development_dependency 'test_construct',    '~> 2.0'
  s.add_development_dependency 'appraisal', '~> 2.1', '>= 2.1'
  s.add_development_dependency 'rake', '>= 10.5', '>= 10.5'
end
