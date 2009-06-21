class ReanmeToFactorId < ActiveRecord::Migration
  def self.up
    rename_column :study_results, :indicators_studies_id, :factor_id
  end

  def self.down
    rename_column :study_results, :factor_id, :indicators_studies_id
  end
end
