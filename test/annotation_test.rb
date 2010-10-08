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


module DummyMod3
  extend Annotation

  if HAVE_INSTANCE_EXEC

    annotation :GET do |method_name, path|
      (@__actions ||= []) << [method_name, :GET, path]
    end
    [:POST, :PUT, :DELETE].each do |req_meth|
      annotation req_meth do |method_name, path|
        (@__actions ||= []) << [method_name, req_meth, path]
      end
    end

  end
end

class Dummy3
  extend DummyMod3

  if HAVE_INSTANCE_EXEC

    GET('/')
    def index2
      "index() called."
    end
    GET('/:id')
    def show2(id)
      "show(#{id.inspect}) called."
    end
    PUT('/:id')
    def update2(id)
      "update(#{id.inspect}) called."
    end

  end
end


module DummyMod4
  extend Annotation

  if HAVE_INSTANCE_EXEC

    annotation :login_required do |method_name|
      orig_method = "_orig_#{method_name}"
      class_eval do
        alias_method orig_method, method_name
        eval "def #{method_name}(*args)
                    raise '403 Forbidden' unless @_current_user
                    #{orig_method}(*args)
                  end"
      end
    end

  end
end

class Dummy4
  extend DummyMod4

  if HAVE_INSTANCE_EXEC

    login_required
    def do_update(*args)
      return "updated: args=#{args.inspect}"
    end

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

    spec "(with block) define annotation method." do
      break unless HAVE_INSTANCE_EXEC
      ok_(Dummy3.respond_to?(:GET))    == true
      ok_(Dummy3.respond_to?(:POST))   == true
      ok_(Dummy3.respond_to?(:PUT))    == true
      ok_(Dummy3.respond_to?(:DELETE)) == true
    end

    spec "callback is called when instance method is defined." do
      #falldown
      expected = [ [:index,  :GET, '/'],
                   [:show,   :GET, '/:id'],
                   [:update, :PUT, '/:id'],
                 ]
      ok_(Dummy1.instance_variable_get('@__actions')) == expected
    end

    spec "(with block) callback is called when instance method is defined." do
      #falldown
      expected = [ [:index2,  :GET, '/'],
                   [:show2,   :GET, '/:id'],
                   [:update2, :PUT, '/:id'],
                 ]
      ok_(Dummy3.instance_variable_get('@__actions')) == expected
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

    spec "(with block) if annotation method is not called then do nothing on method_add." do
      #falldown
      break unless HAVE_INSTANCE_EXEC
      Dummy3.instance_variable_get('@__actions').clear
      Dummy3.class_eval do
        GET('/new')
        def new2
          "new() called."
        end
        def create2
          "create() called."
        end
      end
      ok_(Dummy3.instance_variable_get('@__actions')) == [ [:new2, :GET, '/new'] ]
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

    spec "(with block) callback is called only when method is defined." do
      break unless HAVE_INSTANCE_EXEC
      called = false
      DummyMod3.class_eval do
        annotation :ann1 do |method_name|
          called = true
        end
      end
      ok_(called) == false
      Dummy3.class_eval do
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

    spec "(with block) self in annotation callback is class object." do
      break unless HAVE_INSTANCE_EXEC
      $__self2 = false
      DummyMod3.module_eval do
        annotation :ann2 do |method_name|
          $__self2 = self
        end
      end
      Dummy3.class_eval do
        ann2
        def meth2; end
      end
      #ok_(Dummy3.__send__(:class_variable_get, '@@__self__')) == Dummy3
      ok_($__self2) == Dummy3
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

    spec "(with block) if annotation is specified then call callbacks." do
      break unless HAVE_INSTANCE_EXEC
      annotated = []
      DummyMod4.module_eval do
        @@_annotated_ = annotated
        extend Annotation
        annotation :anno4 do |method_name|
          @@_annotated_ << method_name
        end
      end
      ok_(annotated) == []
      Dummy4.class_eval do
        def foo; end
        anno4
        def bar; end
        anno4
        def baz; end
      end
      ok_(annotated) == [:bar, :baz]
    end

    spec "it is possible to define new method in annotation callback." do
      obj = Dummy2.new
      ok_(obj.respond_to?(:_orig_do_update)) == true
      ok_(proc { obj.do_update(123) }).raise?(RuntimeError, '302 Found')
    end

    spec "(with block) it is possible to define new method in annotation callback." do
      break unless HAVE_INSTANCE_EXEC
      obj = Dummy4.new
      ok_(obj.respond_to?(:_orig_do_update)) == true
      ok_(proc { obj.do_update(123) }).raise?(RuntimeError, '403 Forbidden')
    end

  end


end
