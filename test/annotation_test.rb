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


class Dummy1; end
class Dummy2; end


class AnnotationTest
  include Oktest::TestCase


  def self.spec_of(target, &block)
    define_method("test_#{target}", &block) if block
  end


  spec_of "#annotation"
  def test_annotation

    spec "define annotation method." do
      Dummy1.class_eval do
        extend Annotation
        annotation :GET do |klass, method_name, path|
          (@__actions ||= []) << [method_name, :GET, path]
        end
        [:POST, :PUT, :DELETE].each do |req_meth|
          annotation req_meth do |klass, method_name, path|
            (@__actions ||= []) << [method_name, req_meth, path]
          end
        end
      end
      ok_(Dummy1.respond_to?(:GET))    == true
      ok_(Dummy1.respond_to?(:POST))   == true
      ok_(Dummy1.respond_to?(:PUT))    == true
      ok_(Dummy1.respond_to?(:DELETE)) == true
    end

    spec "callback is called when instance method is defined." do
      #falldown
      Dummy1.class_eval do
        GET('/')
        def index
          "index() called."
        end
        GET('/:id')
        def show(id)
          "show(#{id.inspect}) called."
        end
        PUT('/:id')
        def update(id)
          "update(#{id.inspect}) called."
        end
      end
      expected = [ [:index,  :GET, '/'],
                   [:show,   :GET, '/:id'],
                   [:update, :PUT, '/:id'],
                 ]
      ok_(Dummy1.instance_variable_get('@__actions')) == expected
    end

    spec "if annotation method is not called then do nothing on method_add." do
      #falldown
      Dummy1.instance_variable_get('@__actions').clear
      Dummy1.class_eval do
        GET('/new')
        def new
          "new() called."
        end
        def create
          "create() called."
        end
      end
      ok_(Dummy1.instance_variable_get('@__actions')) == [ [:new, :GET, '/new'] ]
    end

    spec "callback is called only when method is defined." do
      called = false
      Dummy1.class_eval do
        annotation :ann1 do |klass, method_name|
          called = true
        end
      end
      ok_(called) == false
      Dummy1.class_eval do
        ann1
        def meth1; end
      end
      ok_(called) == true
    end

    spec "self in annotation callback is class object." do
      actual = nil
      Dummy1.class_eval do
        annotation :ann2 do |klass, method_name|
          actual = self
        end
        ann2
        def meth2; end
      end
      ok_(actual) == Dummy1
    end

  end


  spec_of "#method_added"
  def test_method_added

    spec "if annotation is specified then call callbacks." do
      annotated = []
      Dummy2.class_eval do
        extend Annotation
        annotation :anno3 do |klass, method_name|
          annotated << method_name
        end
      end
      ok_(annotated) == []
      Dummy2.class_eval do
        def foo; end
        anno3
        def bar; end
        anno3
        def baz; end
      end
      ok_(annotated) == [:bar, :baz]
    end

    spec "it is possible to define new method in annotation callback." do
      Dummy2.class_eval do
        annotation :login_required do |klass, method_name|
          orig_method = "_orig_#{method_name}"
          klass.class_eval do
            alias_method orig_method, method_name
            eval "def #{method_name}(*args)
                    raise '302 Found' unless @_current_user
                    #{orig_method}(*args)
                  end"
          end
        end
        login_required
        def do_update(*args)
          return "updated: args=#{args.inspect}"
        end
      end
      obj = Dummy2.new
      ok_(obj.respond_to?(:_orig_do_update)) == true
      ok_(proc { obj.do_update(123) }).raise?(RuntimeError, '302 Found')
    end

  end


end
