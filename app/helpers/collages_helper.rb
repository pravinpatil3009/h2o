module CollagesHelper
  def path_to_collage_or_collage_version(options = {})
    collage_obj = options[:collage].original || options[:collage]
    collage_version = options[:collage_version]

    if collage_obj.version == collage_version.version
      collage_path(collage_obj)
    else
      collage_version_path(collage_obj, collage_version.version)
    end
  end

  def can_edit_this_collage?
    (current_user.is_collage_admin || current_user.collages.include?(@collage))
  end

end
