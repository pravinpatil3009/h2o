class AutoMigrateCollages < ActiveRecord::Migration
  def self.up
    execute "UPDATE collages SET annotator_version = 2 WHERE id NOT IN (SELECT collage_id FROM annotations) AND id NOT IN (SELECT host_collage_id FROM collage_links)"
    execute "DELETE FROM playlist_items WHERE actual_object_type = 'Playlist' AND actual_object_id IN (SELECT id FROM playlists WHERE user_id = 231)"
    execute "DELETE FROM playlists WHERE user_id = 231"

    Collage.find_in_batches(:batch_size => 100, :conditions => { :annotator_version => 1 }) do |collage_batch|
      collage_batch.each do |collage|
        collage.upgrade_via_nokogiri
      end
    end

    # SET readable state to all updated to ''
    # RESET word count on all
    # DELETE ALL COLLAGE LINKS
  end

  def self.down
  end
end
