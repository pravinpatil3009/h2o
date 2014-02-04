module ApplicationHelper

  def custom_stylesheet_link_tags(stylesheets)
    stylesheets = stylesheets || []
    stylesheets.each do |ss|
       stylesheet_link_tag ss
    end
  end

  def custom_javascript_include_tags(javascripts)
    javascripts = javascripts || []
    javascripts.each do |js|
      javascript_include_tag js
    end
  end

  def cache_specifier(cache_name = nil)
    if Rails.env != 'development'
      cache_name.nil? ? true : cache_name
    else
      false
    end
  end

  def body_id
    "b#{params[:controller]}"
  end

  def body_class(page_cache = false)
    res = "b#{params[:controller]}_#{params[:action]} "
    res += "action_#{params[:action]} "
    res += page_cache_specifier(page_cache)
    res
  end

  def page_cache_specifier(page_cache)
    page_cache ? page_cache : ''
  end
end
