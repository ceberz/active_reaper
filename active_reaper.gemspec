# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_reaper/version"

Gem::Specification.new do |s|
  s.name        = "active_reaper"
  s.version     = ActiveReaper::VERSION
  s.authors     = ["Chris Eberz"]
  s.email       = ["chris@chriseberz.com"]
  s.homepage    = ""
  s.summary     = %q{Your ActiveRecord models can cleanly mark themsleves for deletion after a specifc time.}
  s.description = %q{Set ActiveRecord models to delete themselves after a fixed time, or when a certain criteria is met.}

  s.rubyforge_project = "active_reaper"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib", "spec"]

  s.add_development_dependency "rspec", ">= 2.6"
  s.add_development_dependency "ruby-debug19"
  s.add_development_dependency "sqlite3"
  
  s.add_runtime_dependency "rake"
  s.add_runtime_dependency "activerecord"
  s.add_runtime_dependency "activesupport"
end
