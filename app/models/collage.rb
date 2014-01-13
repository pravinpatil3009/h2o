class Collage < ActiveRecord::Base
  extend RedclothExtensions::ClassMethods
  extend TaggingExtensions::ClassMethods
  extend HeatmapExtensions::ClassMethods

  include H2oModelExtensions
  include StandardModelExtensions::InstanceMethods
  include AncestryExtensions::InstanceMethods
  include AuthUtilities
  include Authorship
  include MetadataExtensions
  include TaggingExtensions::InstanceMethods
  include HeatmapExtensions::InstanceMethods
  include KarmaRounding
  include ActionController::UrlWriter

  RATINGS = {
    :remix => 5,
    :bookmark => 1,
    :add => 3
  }
  RATINGS_DISPLAY = {
    :remix => "Remixed",
    :bookmark => "Bookmarked",
    :add => "Added to"
  }


  acts_as_taggable_on :tags
  acts_as_authorization_object

  def self.annotatable_classes
    Dir.glob(RAILS_ROOT + '/app/models/*.rb').each do |file|
      model_name = Pathname(file).basename.to_s
      model_name = model_name[0..(model_name.length - 4)]
      model_name.camelize.constantize
    end
    # Responds to the annotatable class method with true.
    Object.subclasses_of(ActiveRecord::Base).find_all{|m| m.respond_to?(:annotatable) && m.send(:annotatable)}
  end

  def self.annotatable_classes_select_options
    self.annotatable_classes.collect{|c| [c.model_name]}
  end

  #acts_as_voteable

  before_destroy :collapse_children
  has_ancestry :orphan_strategy => :restrict

  belongs_to :annotatable, :polymorphic => true
  belongs_to :user
  has_many :annotations, :order => 'created_at', :dependent => :destroy
  has_and_belongs_to_many :user_collections   # dependent => destroy
  has_many :defects, :as => :reportable
  has_many :color_mappings
  has_many :playlist_items, :as => :actual_object

  has_many :collage_links, :foreign_key => "host_collage_id"
  has_many :parent_collage_links, :class_name =>  "CollageLink", :foreign_key => "linked_collage_id"
  # Create the content we're going to annotate. This is a might bit inefficient, mainly because
  # we're doing a heavy bit of parsing on each attempted save. It is probably better than allowing
  # the creation of a contentless collage, though.
  before_validation_on_create :prepare_content

  validates_presence_of :annotatable_type, :annotatable_id
  validates_length_of :description, :in => 1..(5.kilobytes), :allow_blank => true

  # TODO: Figure out why tags & annotations breaks in searchable
  searchable do #(:include => [:tags]) do #, :annotations => {:layers => true}]) do
    text :display_name, :stored => true, :boost => 3.0
    string :display_name, :stored => true
    string :id, :stored => true
    text :description, :boost => 2.0

    boolean :active
    boolean :public
    time :created_at
    time :updated_at
    string :tag_list, :stored => true, :multiple => true

    string :user
    string :user_display, :stored => true
    integer :user_id, :stored => true
    string :root_user_display, :stored => true
    integer :root_user_id, :stored => true
    integer :karma
  end

  def fork_it(new_user, params)
    collage_copy = self.clone
    collage_copy.name = params[:name]
    collage_copy.created_at = Time.now
    collage_copy.parent = self
    collage_copy.public = params[:public]
    collage_copy.description = params[:description]
    collage_copy.user = new_user
    self.annotations.each do |annotation|
      new_annotation = annotation.clone
      new_annotation.collage = collage_copy
      new_annotation.cloned = true
      #copy tags
      new_annotation.layer_list = annotation.layer_list
      new_annotation.user = new_user
      new_annotation.save
    end
    self.color_mappings.each do |color_mapping|
      color_mapping = color_mapping.clone
      color_mapping.collage_id = collage_copy.id
      color_mapping.save
    end
    collage_copy.save
    collage_copy
  end

  def color_map
    h = {}
    self.layers.each do |layer|
      map = self.color_mappings.detect { |cm| cm.tag_id == layer.id }
      h["l#{layer.id}"] = map.hex if map
    end
    #hardcoding required layer as dark red
    h["l46"] = '6b0000'
    h
  end
  
  def layer_data
    h = {}
    self.layers.each do |layer|
      map = self.color_mappings.detect { |cm| cm.tag_id == layer.id }
      h["#{layer.name}"] = map.hex if map
    end
    #hardcoding required layer as dark red
    h["required"] = '6b0000'
    h
  end

  def barcode
    Rails.cache.fetch("collage-barcode-#{self.id}") do
      barcode_elements = self.barcode_bookmarked_added
      self.public_children.each do |child|
        barcode_elements << { :type => "remix",
                              :date => child.created_at,
                              :title => "Remixed to Collage #{child.name}",
                              :link => collage_path(child.id) }
      end

      value = barcode_elements.inject(0) { |sum, item| sum += self.class::RATINGS[item[:type].to_sym].to_i; sum }
      self.update_attribute(:karma, value)

      barcode_elements.sort_by { |a| a[:date] }
    end
  end

  def can_edit?
    return current_user.has_role?(:superadmin) || self.owner?
  end

  def display_name
    "#{self.name}, #{self.created_at.to_s(:simpledatetime)}#{(self.user.nil?) ? '' : ' by ' + self.user.login}"
  end

  def layers
    self.annotations.collect{|a| a.layers}.flatten.uniq
  end

  def layer_list
    self.layers.map(&:name)
  end

  def layer_report
    layers = {}
    self.annotations.each do |ann|
      ann.layers.each do |l|
        if layers[l.id].blank?
          layers[l.id] = {:count => 0, :name => l.name, :annotation_count => 0}
        end
        layers[l.id][:count] = layers[l.id][:count].to_i + ann.word_count
        layers[l.id][:annotation_count] = layers[l.id][:annotation_count].to_i + 1
      end
    end
    return layers
  end

  def editable_content_v2
    doc = Nokogiri::HTML.parse(self.annotatable.content)

    # Footnote markup
    doc.css("a").each do |li|
      if li['href'] =~ /^#/
        li['class'] = 'footnote'
      end
    end

    count = 1
    doc.xpath('//p[not(ancestor::center)] | //center | //h2[not(ancestor::center)]').each do |node|
      if node.children.any? && node.text != ''
	      first_child = node.children.first
	      control_node = Nokogiri::XML::Node.new('a', doc)
	      control_node['id'] = "paragraph#{count}"
	      control_node['href'] = "#p#{count}"
	      control_node['class'] = "paragraph-numbering scale0-9"
	      control_node.inner_html = "#{count}"
	      first_child.add_previous_sibling(control_node)
	      count += 1
      end
    end

    CGI.unescapeHTML(doc.xpath("//html/body/*").to_s)
  end

  def editable_content
    doc = Nokogiri::HTML.parse(self.content)

    # Footnote markup
    doc.css("a").each do |li|
      if li['href'] =~ /^#/
        li['class'] = 'footnote'
      end
    end

    # data-id markup
    x = 1
    doc.xpath('//tt').each do |node|
      node['data-id'] = x.to_s
      x+=1
    end

    count = 1
    doc.xpath('//p[not(ancestor::center)] | //center | //h2[not(ancestor::center)]').each do |node|
      tt_size = node.css('tt').size  #xpath tt isn't working because it's not selecting all children (possible TODO later)
      if node.children.size > 0 && tt_size > 0
        first_child = node.children.first
        control_node = Nokogiri::XML::Node.new('a', doc)
        control_node['id'] = "paragraph#{count}"
        control_node['href'] = "#p#{count}"
        control_node['class'] = "paragraph-numbering scale0-9"
        control_node.inner_html = "#{count}"
        first_child.add_previous_sibling(control_node)
        count += 1
      end
    end

    CGI.unescapeHTML(doc.xpath("//html/body/*").to_s)
  end

  def current?
    !self.outdated?
  end

  def outdated?
    self.annotatable.version > self.annotatable_version
  end

  def update_annotatable_version_number
    if self.new_record?
      if self.annotatable
        self.annotatable.reload
        if self.annotatable.respond_to?(:version)
          self.annotatable_version = self.annotatable.version
        end
      end
    end
  end

  alias :to_s :display_name

  def xpath_and_offset(doc, tt_pos, anchor)
    results = { :xpath => '', :offset => 0 }
    node = doc.xpath("//tt[@id='#{tt_pos}']").first
    element = node.parent
    while element.name != 'body'
      index = element.xpath("../#{element.name}").index(element) + 1
      results[:xpath] = "/#{element.name}[#{index}]#{results[:xpath]}"
      element = element.parent
    end

    nodes = node.xpath('../tt')
    node_index = nodes.index(node)

    if anchor == 'start'
      if node_index != 0
        results[:offset] = nodes[0,node_index].collect { |n| n.text }.join('').length
      end
    else
      results[:offset] = nodes[0,node_index + 1].collect { |n| n.text }.join('').length
    end

    results
  end

  def upgrade_via_nokogiri
    doc = Nokogiri::HTML.parse(self.content)
 
    self.annotations.each do |annotation|
      start_detail = xpath_and_offset(doc, annotation.annotation_start, 'start')
      
      end_detail = xpath_and_offset(doc, annotation.annotation_end, 'end')
      attributes = { :xpath_start => start_detail[:xpath],
                     :xpath_end => end_detail[:xpath], 
                     :start_offset => start_detail[:offset],
                     :end_offset => end_detail[:offset] } 
      annotation.update_attributes(attributes)
    end
    
    self.collage_links.each do |collage_link|
      start_detail = xpath_and_offset(doc, collage_link.link_text_start, 'start')
      end_detail = xpath_and_offset(doc, collage_link.link_text_end, 'end')

	    Annotation.create({ :collage_id => self.id,
	                        :xpath_start => start_detail[:xpath],
	                        :xpath_end => end_detail[:xpath],
	                        :start_offset => start_detail[:offset],
	                        :end_offset => end_detail[:offset],
	                        :linked_collage_id => collage_link.linked_collage_id,
	                        :user_id => self.user_id,
                          :annotation_start => 0,
                          :annotation_end => 0,
                          :annotation => '' })
    end
    #CollageLink.destroy(self.collage_links)

    self.update_attribute(:annotator_version, 2)
  end

  private

  def prepare_content
    if self.content.blank?
      content_to_prepare = self.annotatable.content.gsub(/<br>/,'<br /> ')
      doc = Nokogiri::HTML.parse(content_to_prepare)
      doc.xpath('//*').each do |child|
        child.children.each do|c|
          if c.class == Nokogiri::XML::Text && ! c.content.blank?
            text_content = c.content.scan(/\S*\s*/).delete_if(&:empty?).map do |word|
              "<tt>" + word + '</tt> '
            end.join(' ')

            c.swap(text_content)
          end
        end
      end
      class_counter = 1
      indexable_content = []
      doc.xpath('//tt').each do |n|
        n['id'] = "t#{class_counter}"
        class_counter +=1
        indexable_content << n.text.strip
      end
      self.word_count = class_counter
      self.words_shown = class_counter
      self.indexable_content = indexable_content.join(' ')
      self.content = doc.xpath("//html/body/*").to_s
    end
  end
end
