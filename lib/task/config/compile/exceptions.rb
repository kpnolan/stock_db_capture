#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
 module Task
   module Config
     module Compile
       #
       # These Exceptions can only be raise only during a "validate" or during the load of the task config file
       #
       class TaskException < Exception
         def initialize(msg)
           super(msg)
         end
       end

       class TypeException < Exception
         def initialize(msg)
           super(msg)
         end
       end
     end
     #
     # raised when the signature for the wrapped task does not have the stander wrapper input args, i.e. :position
     #
     class WrapperException < Exception
       def initialize(msg)
         super(msg)
       end
     end

     module Runtime
      #
      # raise only during a the realtime running of tasks within the Task Server
      #
      class TaskException < Exception
        def initialize(msg)
          super
        end
      end

      class TypeException < Exception
        def initialize(msg)
          super
        end
      end
      #
      # raise when there is a problem initializing, delivering, or Receiving Messages
      #
      class MsgException < Exception
        def initialize(msg)
          super
        end
      end
      #
      # raise when there is a problem executing a Wrapper proc, only raise when the expected output args
      # will not be available (in the case of a nil result)
      #
      class WrapperException < Exception
        def initialize(msg)
          super
        end
      end
    end
  end
end

