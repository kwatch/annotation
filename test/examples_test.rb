# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

$: << 'lib'    if File.file?('lib/annotation.rb')
$: << '../lib' if File.file?('../lib/annotation.rb')
$: << 'test'   if File.file?('test/annotation_test.rb')


require 'oktest'
require 'annotation'


HAVE_INSTANCE_EXEC = RUBY_VERSION >= '1.8.7' unless defined?(HAVE_INSTANCE_EXEC)


module ControllerAnnotation
  extend Annotation

  def GET(imethod, path)
    (@__routes ||= []) << [path, :GET, imethod]
  end

  def POST(imethod, path)
    (@__routes ||= []) << [path, :POST, imethod]
  end

  def login_required(imethod)
    alias_method "__orig_#{imethod}", imethod
    s = "def #{imethod}(*args)
           raise '302 Found' unless @current_user
           __orig_#{imethod}(*args)
         end"
    self.class_eval s    # not 'eval(s)'
  end

  annotation :GET, :POST, :login_required

end


class Controller
  extend ControllerAnnotation
end


class MyController < Controller

  GET('/')
  def index
    "index() called."
  end

  GET('/:id')
  def show(id)
    "show(#{id}) called."
  end

  POST('/:id')
  login_required
  def update(id)
    "update(#{id}) called."
  end

  #p @__routes   #=> [["/", :GET, :index],
  #              #    ["/:id", :GET, :show],
  #              #    ["/:id", :POST, :update]]
end


#p MyController.new.show(123)     #=> 302 Found (RuntimeError)


class FunctionalTest
  include Oktest::TestCase


  def test_FUNC_class_instance_variable
    actual = MyController.instance_variable_get('@__routes')
    expected = [["/", :GET, :index], ["/:id", :GET, :show], ["/:id", :POST, :update]]
    ok_(actual) == expected
  end


  def test_FUNC_method_override
    ok_(proc { MyController.new.update(123) }).raise?(RuntimeError, '302 Found')
  end


end