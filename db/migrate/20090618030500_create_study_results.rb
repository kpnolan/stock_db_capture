class CreateStudyResults < ActiveRecord::Migration
  def self.up
    create_table :study_results do |t|
      t.integer :indicators_studies_id
      t.date :date
      t.float :value
    end
  end

  def self.down
    drop_table :study_results
  end
end
