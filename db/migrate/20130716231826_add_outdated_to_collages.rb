class AddOutdatedToCollages < ActiveRecord::Migration
  def self.up
    add_column :collages, :outdated, :boolean
    add_column :collage_versions, :outdated, :boolean
  end

  def self.down
    remove_column :collage_versions, :outdated
    remove_column :collages, :outdated
  end
end