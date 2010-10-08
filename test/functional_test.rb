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


class Controller
  extend Annotation

  def self.GET(imethod, path)
    (@__routes ||= []) << [path, :GET, imethod]
  end

  def self.login_required(imethod)
    alias_method "__orig_#{imethod}", imethod
    s = "def #{imethod}(*args)
           raise '302 Found' unless @current_user
           __orig_#{imethod}(*args)
         end"
    self.class_eval s    # not 'eval(s)'
  end

  annotation :GET, :login_required

  annotation :POST do |imethod, path|
    (@__routes ||= []) << [path, :POST, imethod]
  end  if HAVE_INSTANCE_EXEC

  annotation :admin_required do |imethod|
    alias_method "__orig_#{imethod}", imethod
    s = "def #{imethod}(*args)
           raise '403 Forbidden' unless @admin_user
           __orig_#{imethod}(*args)
         end"
    self.class_eval s    # not 'eval(s)'
  end  if HAVE_INSTANCE_EXEC

end


class MyController < Controller

  GET('/')
  def index
    "index() called."
  end

  POST('/') if HAVE_INSTANCE_EXEC
  def create
    "create() called."
  end

  GET('/:id')
  login_required
  def show(id)
    "show(#{id}) called."
  end

  POST('/:id') if HAVE_INSTANCE_EXEC
  admin_required if HAVE_INSTANCE_EXEC
  def update(id)
    "update(#{id}) called."
  end

  #p @__routes   #=> [["/", :GET, :index],
  #              #    ["/", :POST, :create],
  #              #    ["/:id", :GET, :show],
  #              #    ["/:id", :POST, :update]]
end


#p MyController.new.show(123)     #=> 302 Found (RuntimeError)
#p MyController.new.update(123)   #=> 403 Forbidden (RuntimeError)


class FunctionalTest
  include Oktest::TestCase


  def test_FUNC_class_instance_variable
    actual = MyController.instance_variable_get('@__routes')
    expected = [["/", :GET, :index], ["/", :POST, :create],
                ["/:id", :GET, :show], ["/:id", :POST, :update]]
    expected = [["/", :GET, :index], ["/:id", :GET, :show] ] unless HAVE_INSTANCE_EXEC
    ok_(actual) == expected
  end


  def test_FUNC_method_override
    ok_(proc { MyController.new.show(123) }).raise?(RuntimeError, '302 Found')
    if HAVE_INSTANCE_EXEC
      ok_(proc { MyController.new.update(123) }).raise?(RuntimeError, '403 Forbidden')
    end
  end


end
