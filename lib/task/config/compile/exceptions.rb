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

