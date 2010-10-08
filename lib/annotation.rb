# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

###
### annotation.rb -- annotation library for ruby
###
### ex.
###
###    require 'annotation'
###
###
###    class Controller
###      extend Annotation
###
###      def self.GET(imethod, path)
###        (@__routes ||= []) << [path, :GET, imethod]
###      end
###
###      def self.POST(imethod, path)
###        (@__routes ||= []) << [path, :POST, imethod]
###      end
###
###      def self.login_required(imethod)
###        alias_method "__orig_#{imethod}", imethod
###        s = "def #{imethod}(*args)
###               raise '302 Found' unless @current_user
###               __orig_#{imethod}(*args)
###             end"
###        self.class_eval s    # not 'eval(s)'
###      end
###
###      annotation :GET, :POST, :login_required
###
###    end
###
###
###    class MyController < Controller
###
###      GET('/')
###      def index
###        "index() called."
###      end
###
###      GET('/:id')
###      def show(id)
###        "show(#{id}) called."
###      end
###
###      POST('/:id')
###      login_required
###      def update(id)
###        "update(#{id}) called."
###      end
###
###      p @__routes   #=> [["/", :GET, :index],
###                    #    ["/:id", :GET, :show],
###                    #    ["/:id", :POST, :update]]
###    end
###
###
###    p MyController.new.update(123)   #=> 302 Found (RuntimeError)
###
module Annotation

  VERSION = "$Release: 0.0.0 $".split(' ')[1]

  def annotation(*names)
    self.class_eval do
      s = ""
      names.each do |name|
        aliased = alias_name(name)
        alias_method aliased, name
        s << "def #{name}(*args)
                (@__annotations ||= []) << [:#{aliased}, args]
              end\n"
      end
      self.class_eval s
    end
  end

  private

  def alias_name(method_name)
    "__anno_#{method_name}".intern
    #"__anno_#{method_name}_#{rand().to_s[2..10]}".intern
  end

  def self.extended(other)
    other.module_eval do
      #private
      #def method_added(method_name) ... end
      include MethodAdded
    end
  end

  module MethodAdded
    private
    def method_added(method_name)
      super
      if @__annotations && ! @__anno_processing
        @__anno_processing = true   # necessary to avoid infinite recursive call
        @__annotations.each do |aliased, args|
          __send__(aliased, method_name, *args)
        end
        @__annotations = nil
        @__anno_processing = false
      end
    end
  end

end
