# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def remove_child_link(name, f)
    f.hidden_field(:_destroy) + link_to(name, "javascript:void(0)", :class => "remove_child")
  end

  def add_child_link(name, association)
    link_to(name, "javascript:void(0)", :class => "add_child", :"data-association" => association)
  end

  def new_child_fields_template(form_builder, association, options = {})
    options[:object] ||= form_builder.object.class.reflect_on_association(association).klass.new
    options[:partial] ||= association.to_s.singularize
    options[:form_builder_local] ||= :f

    res = content_tag(:div, :id => "#{association}_fields_template", :style => "display: none") do
      form_builder.fields_for(association, options[:object], :child_index => "new_#{association}") do |f|
        render(:partial => options[:partial], :locals => {options[:form_builder_local] => f})
      end
    end
    CGI::unescapeHTML(res)
  end

  def top_ancestor(klass, item)
    if !item.ancestry.nil?
      parent_id = item.ancestry.split('/').first
      klass.find(parent_id)
    else
      item
    end
  end

  def path_to_object_or_object_version(options = {})
    obj = options[:obj].original || options[:obj]
    obj_version = options[:obj_version]

    if obj.version == obj_version.version
      self.send("#{obj.class.to_s.downcase}_path", obj)
    else
      self.send("#{obj.class.to_s.downcase}_version_path", obj, obj_version.version)
    end
  end

  def version_text(obj, obj_version)
    if obj.versions.first == obj_version
     res = "Current"
    else
     res = "Version #{obj_version.version}"
    end
    if (obj.version == obj_version.version)
      res += " (Viewing)" if (obj.version == obj_version.version)
      res = content_tag(:strong, res)
    end
    res
  end

  def version_list_item(obj, obj_version)
    if obj.version == obj_version.version
      res = content_tag(:li, version_text(obj, obj_version))
    else
      res = content_tag(:li, link_to(version_text(obj, obj_version), path_to_object_or_object_version(:obj => obj, :obj_version => obj_version)))
    end
    res
  end

  def current_version?
    obj = @case || @collage
    !obj.copy?
  end

end
