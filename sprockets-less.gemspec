# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sprockets/less/version"

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
  s.add_dependency 'less', '~> 2.3.0'
  s.add_dependency 'tilt', '~> 1.1'
  s.add_development_dependency 'sprockets-helpers', '~> 0.6'
  s.add_development_dependency 'rspec',             '~> 2.6'
  s.add_development_dependency 'test-construct',    '~> 1.2'
  s.add_development_dependency 'rake'
end
