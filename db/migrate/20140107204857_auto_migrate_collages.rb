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

    execute "UPDATE collages SET readable_state = ''"
    execute "UPDATE collages SET words_shown = word_count"
    # Later TODO: DELETE ALL COLLAGE LINKS, Remove CollageLink model, Remove tt columns from collages
  end

  def self.down
  end
end
