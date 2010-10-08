# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

release    = '0.1.0'
project    = 'Annotation'
gem_name   = 'annotation'
copyright  = 'copyright(c) 2010 kuwata-lab.com all rights reserved'
license    = 'MIT-License'
text_files = %w[README.txt CHANGES.txt MIT-LICENSE setup.rb annotation.gemspec]


desc "do all"
task :all => text_files

desc "create packages"
task :packages => [ "#{gem_name}-#{release}.gem" ]

desc "do test"
task :test do
  sh "ruby test/annotation_test.rb"
  sh "ruby test/examples_test.rb"
end

desc "clear files"
task :clear do
  rm_f "#{gem_name}-*.*"
  rm_f '**/*.rbc'
end


desc "generate gem file"
task :gem => [:clear] do |t|
  # delete and create directory
  base = "#{gem_name}-#{release}"
  dir  = "build/#{base}"
  rm_rf dir if File.exist?(dir)
  #
  #store 'lib/**/*', 'test/**/*', text_files, dir
  mkdir_p dir; cp text_files, dir
  mkdir_p "#{dir}/lib";  Dir.glob("lib/*.rb").each {|x| cp x, "#{dir}/lib" }
  mkdir_p "#{dir}/test"; Dir.glob("test/*.rb").each {|x| cp x, "#{dir}/test" }
  #
  edit "#{dir}/**/*" do |content|
    content.gsub!(/\$Release:.*?\$/,   "$Release: #{release} $")
    content.gsub!(/\$Release\$/,       release)
    content.gsub!(/\$License:.*?\$/,   "$License: #{license} $")
    content.gsub!(/\$License\$/,       license)
    content.gsub!(/\$Copyright:.*?\$/, "$Copyright: #{copyright} $")
    content.gsub!(/\$Copyright\$/,     copyright)
    content
  end
  #
  chdir "build" do
    sh "tar czf #{base}.tar.gz #{base}"
  end
  chdir dir do
    sh "gem build #{gem_name}.gemspec"
  end
  mv "#{dir}/#{base}.gem", "build"
end


def edit(*filepaths)
  filepaths.collect {|fpath| Dir.glob(fpath) }.flatten.each do |fname|
    next unless File.file?(fname)
    s = File.open(fname, 'rb') {|f| f.read }
    s = yield s
    File.open(fname, 'wb') {|f| f.write(s) }
  end
end
