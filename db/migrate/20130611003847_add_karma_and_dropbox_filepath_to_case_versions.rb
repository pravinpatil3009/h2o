class AddKarmaAndDropboxFilepathToCaseVersions < ActiveRecord::Migration
  def self.up
    add_column :case_versions, :karma, :integer
    add_column :case_versions, :dropbox_filepath, :string
    add_column :collage_versions, :karma, :integer
  end

  def self.down
    remove_column :case_versions, :dropbox_filepath
    remove_column :case_versions, :karma
    remove_column :collage_versions, :karma

  end
end
