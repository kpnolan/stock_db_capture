class CreateHistoricalAttributes < ActiveRecord::Migration
  def self.up
    create_table :historical_attributes do |t|
      t.string :name
    end
    %w{ open close low high volume adj_close lhratio }.each do |attr|
      HistoricalAttribute.create(:name => attr)
    end
  end

  def self.down
    drop_table :historical_attributes
  end
end
