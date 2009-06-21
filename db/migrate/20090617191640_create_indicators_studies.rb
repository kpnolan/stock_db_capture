class CreateIndicatorsStudies < ActiveRecord::Migration
  def self.up
    create_table :indicators_studies do |t|
      t.integer :study_id
      t.integer :indicator_id
      t.string :params_str
    end
  end

  def self.down
    drop_table :indicators_studies
  end
end
