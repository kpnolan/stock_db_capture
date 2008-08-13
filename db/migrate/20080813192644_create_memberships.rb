require 'populate_db'

class CreateMemberships < ActiveRecord::Migration
  def self.up
    Membership.transaction do
      create_table :memberships do |t|
        t.integer :ticker_id
        t.integer :listing_category_id
      end
      begin
        TradingDBLoader.load_memberships()
      rescue
        drop_table :memberships
        raise
      end
    end
  end

  def self.down
    drop_table :memberships
  end
end
