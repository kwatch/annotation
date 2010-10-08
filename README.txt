= README

release::   $Release$
copyright:: $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
license::   $License: MIT License $



== About

'annotation.rb' is a very small but pretty good library to introduce Java's
annotation or Python's function decorator into Ruby.
Using 'annotatin.rb', you can write your code more declarative, like:

    class MyController < Controller

      GET('/')
      def index; ...; end

      GET('/:id')
      def show(id); ...; end

      PUT('/:id')
      login_required
      def update(id); ...; end

    end



== Install

Install rubygems at first and:

    $ gem install annotation



== Examples


ex1. my_controller.rb:

    require 'annotation'


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

      annotation :GET, :POST, :login_required         # !!!!!!

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

      p @__routes   #=> [["/", :GET, :index],
                    #    ["/:id", :GET, :show],
                    #    ["/:id", :POST, :update]]
    end


    p MyController.new.update(123)   #=> 302 Found (RuntimeError)



ex2. memoize.rb

    require 'annotation'

    module Memoize
      extend Annotation

      def memoize(func_name)
        aliased = "_orig_#{func_name}"   # or "_#{func_name}_#{rand().to_s[2..9]}"
        alias_method aliased, func_name
        s = "def #{func_name}(*args)
               @_memos ||= {}
               hash = (@_memos[:#{func_name}] ||= {})
               hash[args] = __send__(:#{aliased}, *args) unless hash.key?(args)
               return hash[args]
             end"
        class_eval s
      end
      annotation :memoize         # !!!!!!

    end

    class Fib
      extend Memoize

      def fib1(n)
        n <= 2 ? 1 : fib1(n-1) + fib1(n-2)
      end

      memoize                     # !!!!
      def fib2(n)
        n <= 2 ? 1 : fib2(n-1) + fib2(n-2)
      end

    end

    require 'benchmark'
    fib = Fib.new
    Benchmark.bm(20) do |x|
      x.report('fib1(30)') { ret = fib.fib1(30) }
      x.report('fib2(30)') { ret = fib.fib2(30) }
    end

    ### Result:
    # $ ruby memoize.rb
    #                           user     system      total        real
    # fib1(30)              1.060000   0.000000   1.060000 (  1.063110)
    # fib2(30)              0.000000   0.000000   0.000000 (  0.000327)



ex3. obsolete.rb

    require 'annotation'

    module Obsolete
      extend Annotation

      def obsolete(method)
        aliased = "_orig_#{method}"  # or "_#{method}_#{rand().to_s[2..9]}"
        alias_method aliased, method
        s = "def #{method}(*args)
               warn %Q`*** warning: #{method} is obsolete.`
               __send__(:#{aliased}, *args)
             end"
        class_eval s
      end
      annotation :obsolete          # !!!!!!

    end

    class Hello
      extend Obsolete

      obsolete                      # !!!!!!
      def hello(name)
        puts "Hello #{name}!"
      end

    end


    Hello.new.hello('World')   #=> *** warning: hello is obsolete.



ex4. my_test.rb

    require 'test/unit'
    require 'annotation'

    module DummyFiles
      extend Annotation

      def dummy_files(method_name, files={})
        aliased = "__#{method_name}_#{rand().to_s[2..10]}"
        alias_method aliased, method_name
        define_method method_name do
          begin
            files.each do |filename, content|
              next unless content
              File.open(filename, 'w') {|f| f.write(content) }
            end
            __send__(aliased)
          ensure
            files.each do |filename, _|
              File.unlink(filename) if File.exist?(filename)
            end
          end
        end
      end
      annotation :dummy_files         # !!!!!!

    end


    class MyTestCase < Test::Unit::TestCase
      extend DummyFiles

      dummy_files 'A.txt'=>'AAA', 'B.txt'=>'BBB'   # !!!!!!
      def test_something
        assert_equal 'AAA', File.read('A.txt')
        assert_equal 'BBB', File.read('B.txt')
      end

    end



== Known Issues

* Annotation and RDoc cannot be good friends.

      ## ...document...
      GET('/')   # this annotation prevent RDoc to generate document!
      def index()
        ...
      end
