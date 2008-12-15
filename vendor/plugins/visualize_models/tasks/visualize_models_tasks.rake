desc "Visualize the model structure (as .png image)"

task :visualize_models do
   require File.join(File.dirname(__FILE__), "../lib/visualize_models.rb")
   VisualizeModels.do_visualize
end