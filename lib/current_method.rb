# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module CurrentMethod
  def this_method
    caller[0][/`([^']*)'/, 1]
  end
  def calling_method(frame=1)
    caller[frame][/`([^']*)'/, 1]
  end
end
