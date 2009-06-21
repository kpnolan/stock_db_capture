class AddTidToStudyResult < ActiveRecord::Migration
  def self.up
    add_column :study_results, :ticker_id, :integer
  end

  def self.down
    remove_column :study_results, :ticker_id
  end
end
