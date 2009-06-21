class CreateStudies < ActiveRecord::Migration
  def self.up
    create_table :studies, :force => true do |t|
      t.string :name
      t.string :description
      t.date :start_date
      t.date :end_date
    end
  end

  def self.down
    drop_table :studies
  end
end
