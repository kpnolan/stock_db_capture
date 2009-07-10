# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module PlotAuxInfo
  def plot_commands_for(function)
    case function
      when :aroon then
      script = <<DONE
set ytics (0,30,70,100)
set grid ytics noxtics
DONE
     else
      script = ''
    end
    script
  end
end
