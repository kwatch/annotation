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


module DummyMod1
  extend Annotation
  def GET(method_name, path)
    (@__actions ||= []) << [method_name, :GET, path]
  end
  annotation :GET
  [:POST, :PUT, :DELETE].each do |req_meth|
    define_method req_meth do |method_name, path|
      (@__actions ||= []) << [method_name, req_meth, path]
    end
  end
  annotation :POST, :PUT, :DELETE
end

class Dummy1
  extend DummyMod1

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


module DummyMod2
  extend Annotation
  def login_required(method_name)
    orig_method = "_orig_#{method_name}"
    class_eval do
      alias_method orig_method, method_name
      eval "def #{method_name}(*args)
              raise '302 Found' unless @_current_user
              #{orig_method}(*args)
            end"
    end
  end
  annotation :login_required
end

class Dummy2
  extend DummyMod2
  login_required
  def do_update(*args)
    return "updated: args=#{args.inspect}"
  end
end



class AnnotationTest
  include Oktest::TestCase


  def self.spec_of(target, &block)
    define_method("test_#{target}", &block) if block
  end


  spec_of "#annotation"
  def test_annotation

    spec "define annotation method." do
      ok_(Dummy1.respond_to?(:GET))    == true
      ok_(Dummy1.respond_to?(:POST))   == true
      ok_(Dummy1.respond_to?(:PUT))    == true
      ok_(Dummy1.respond_to?(:DELETE)) == true
    end

    spec "annotation method should be protected." do
      msg = "protected method `GET' called for Dummy1:Class"
      ok_(proc { Dummy1.GET('/') }).raise?(NoMethodError, msg)
    end

    spec "aliased method should be private." do
      ok_(Dummy1.methods.grep(/^GET$/).length) == 1
      ok_(Dummy1.private_methods.grep(/^__anno_GET/).length) == 1
    end

    spec "callback is called when instance method is defined." do
      #falldown
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
      DummyMod1.module_eval do
        define_method :ann1 do |method_name|
          called = true
        end
        annotation :ann1
      end
      ok_(called) == false
      Dummy1.class_eval do
        ann1
        def meth1; end
      end
      ok_(called) == true
    end

    spec "self in annotation callback is class object." do
      $__self = false
      DummyMod1.class_eval do
        def ann2(method_name)
          $__self = self
        end
        annotation :ann2
      end
      Dummy1.class_eval do
        ann2
        def meth2; end
      end
      #ok_(Dummy1.__send__(:class_variable_get, '@@__self__')) == Dummy1
      ok_($__self) == Dummy1
    end

  end


  spec_of "#method_added"
  def test_method_added

    spec "if annotation is specified then call callbacks." do
      annotated = []
      DummyMod2.module_eval do
        @@_annotated_ = annotated
        extend Annotation
        def anno3(method_name)
          @@_annotated_ << method_name
        end
        annotation :anno3
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
      obj = Dummy2.new
      ok_(obj.respond_to?(:_orig_do_update)) == true
      ok_(proc { obj.do_update(123) }).raise?(RuntimeError, '302 Found')
    end

  end


end
