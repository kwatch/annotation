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


class Controller
  extend Annotation

  annotation :GET do |klass, imethod, path|
    klass.class_eval do
      (@__actions ||= []) << [imethod, :GET, path]
    end
  end

  [:POST, :PUT, :DELETE].each do |req_meth|
    annotation req_meth do |klass, imethod, path|
      klass.class_eval do
        (@__actions ||= []) << [imethod, req_meth, path]
      end
    end
  end

  annotation :login_required do |klass, imethod, path|
    klass.class_eval do
      alias_method "__orig_#{imethod}", imethod
      s = "def #{imethod}(*args)
             raise '302 Found' unless @current_user
             __orig_#{imethod}(*args)
           end"
      eval s
    end
  end

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

  #p @__actions   #=> [[:index, :GET, "/"],
  #               #    [:show, :GET, "/:id"],
  #               #    [:update, :POST, "/:id"]]
end


#MyController.new.update(123)   #=> 302 Found (RuntimeError)

class FunctionalTest
  include Oktest::TestCase


  def test_FUNC_class_instance_variable
    actual = MyController.instance_variable_get('@__actions')
    ok_(actual) == [[:index, :GET, "/"], [:show, :GET, "/:id"], [:update, :POST, "/:id"]]
  end


  def test_FUNC_method_override
    ok_(proc { MyController.new.update(123) }).raise?(RuntimeError, '302 Found')
  end


end
