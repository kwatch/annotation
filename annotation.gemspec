#!/usr/bin/ruby

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###


require 'rubygems'

spec = Gem::Specification.new do |s|
  ## package information
  s.name        = "annotation"
  s.author      = "makoto kuwata"
  s.email       = "kwa(at)kuwata-lab.com"
  s.rubyforge_project = 'annotation'
  s.version     = "$Release$"
  s.platform    = Gem::Platform::RUBY
  s.homepage    = "http://www.kuwata-lab.com/annotation/"
  s.summary     = "annotation library similar to Java or Python"
  s.description = <<-'END'
  Annotation.rb is a very small but pretty good library which introduces
  Java's annotation or Python's functhon decorator into Ruby.
  END

  ## files
  files = []
  files += Dir.glob('lib/**/*')
  files += Dir.glob('bin/*')
  #files += Dir.glob('examples/**/*')
  files += Dir.glob('test/**/*')
  #files += Dir.glob('doc/**/*')
  #files += Dir.glob('examples/**/*')
  files += %w[README.txt CHANGES.txt MIT-LICENSE setup.rb annotation.gemspec]
  #files += Dir.glob('contrib/*')
  #files += Dir.glob('benchmark/**/*')
  #files += Dir.glob('doc-api/**/*')
  s.files       = files
  #s.executables = ['']
  #s.bindir      = 'bin'
  s.test_file   = 'test/annotation_test.rb'
end


if $0 == __FILE__
  Gem::manage_gems
  Gem::Builder.new(spec).build
end
