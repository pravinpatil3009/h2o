class Media < ActiveRecord::Base
  extend TaggingExtensions::ClassMethods

  include StandardModelExtensions::InstanceMethods
  include AuthUtilities
  include Authorship
  include KarmaRounding
  include ActionController::UrlWriter

  RATINGS = {
    :bookmark => 1,
    :add => 3
  }

  acts_as_authorization_object
  acts_as_taggable_on :tags

  belongs_to :media_type
  belongs_to :user
  validates_presence_of :name, :media_type_id, :content
  has_many :playlist_items, :as => :actual_object

  def is_pdf?
    self.media_type.slug == 'pdf'
  end

  def typed_content
    self.is_pdf? ? self.pdf_content : self.content
  end

  def pdf_content
    self.has_html? ? self.content : "<iframe src='#{self.content.strip}' width='100%' height='100%'></iframe>"
  end

  def has_html?
    self.content =~ /<\/?\w+((\s+\w+(\s*=\s*(?:".*?"|'.*?'|[^'">\s]+))?)+\s*|\s*)\/?>/imx
  end

  def display_name
    self.name
  end

  searchable(:include => [:tags]) do #, :annotations => {:layers => true}]) do
    string :id, :stored => true
    text :display_name, :boost => 3.0
    string :display_name, :stored => true
    text :content, :stored => true
    string :content
    integer :karma

    boolean :active
    boolean :public
    string :tag_list, :stored => true, :multiple => true

    time :created_at
    time :updated_at
    string :user
    string :user_display, :stored => true
    integer :user_id, :stored => true

    string :media_type do
      media_type.slug
    end

    # TODO: add stored media type slug here
  end

  def barcode
    Rails.cache.fetch("media-barcode-#{self.id}") do
      barcode_elements = self.barcode_bookmarked_added.sort_by { |a| a[:date] }

      value = barcode_elements.inject(0) { |sum, item| sum += self.class::RATINGS[item[:type].to_sym].to_i; sum }
      self.update_attribute(:karma, value)

      barcode_elements
    end
  end
end
