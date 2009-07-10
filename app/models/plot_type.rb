# == Schema Information
# Schema version: 20090707232154
#
# Table name: plot_types
#
#  id           :integer(4)      not null, primary key
#  name         :string(255)
#  source_model :string(255)
#  method       :string(255)
#  time_class   :string(255)
#  resolution   :string(255)
#  inputs       :string(255)
#  num_outputs  :integer(4)
#
# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class PlotType < ActiveRecord::Base
end
