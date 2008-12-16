class CreateListingCategories < ActiveRecord::Migration
  def self.up
    create_table :listing_categories, :force => true do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :listing_categories
  end
end
