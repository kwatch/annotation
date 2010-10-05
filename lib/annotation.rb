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
###      annotation :GET do |klass, imethod, path|
###        klass.class_eval do
###          (@__actions ||= []) << [imethod, :GET, path]
###        end
###      end
###
###      [:POST, :PUT, :DELETE].each do |req_meth|
###        annotation req_meth do |klass, imethod, path|
###          klass.class_eval do
###            (@__actions ||= []) << [imethod, req_meth, path]
###          end
###        end
###      end
###
###      annotation :login_required do |klass, imethod, path|
###        klass.class_eval do
###          alias_method "__orig_#{imethod}", imethod
###          s = "def #{imethod}(*args)
###                 raise '302 Found' unless @current_user
###                 __orig_#{imethod}(*args)
###               end"
###          eval s
###        end
###      end
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
###      p @__actions   #=> [[:index, :GET, "/"],
###                     #    [:show, :GET, "/:id"],
###                     #    [:update, :POST, "/:id"]]
###    end
###
###
###    MyController.new.update(123)   #=> 302 Found (RuntimeError)
###
module Annotation

  VERSION = "$Release: 0.0.0 $".split(' ')[1]

  def annotation(name, &block)
    key = name.is_a?(Symbol) ? name : name.to_s.intern
    (@@__anno_callbacks ||= {})[key] = block
    s = "def self.#{name}(*args)
           (@__annotations ||= []) << [:#{name}, args]
         end;"
    eval s   # or self.class_eval(s) ?
  end

  private

  def method_added(method_name)
    if @__annotations && ! @__anno_processing
      @__anno_processing = true   # necessary to avoid infinite recursive call
      @__annotations.each do |name, args|
        callback = @@__anno_callbacks[name]  or
          raise "*** assertion failed: annotiaion '#{name}' not found."
        callback.call(self, method_name, *args)
      end
      @__annotations = nil
      @__anno_processing = false
    end
  end

end
