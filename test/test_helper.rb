ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require "authlogic/test_case"

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
#  fixtures :all

  # Add more helper methods to be used by all tests here...
  def setup_case
    setup_h2ocases_user
    @case = Case.create!(:short_name => 'first case', :content => 'first_content')
  end

  def setup_collage(name = "first", content = "first", collage_arg = nil)
    collage = Collage.new
    collage.name = name
    collage.annotatable = @case
    collage.content = content
    collage.save!
    @collage = collage if collage_arg.nil?
    collage
  end

  def setup_case_jurisdiction
    @case_jurisdiction = CaseJurisdiction.new
    @case_jurisdiction.abbreviation = "abbv"
    @case_jurisdiction.name = "first"
    @case_jurisdiction.save!
  end

  def setup_annotation
    @annotation = Annotation.new
    @annotation.collage = @collage
    @annotation.annotated_content = "first content"
    @annotation.annotation = "content"
    @annotation.annotation_start = "T1"
    @annotation.annotation_end = "T100"
    @annotation.save!
  end

  def setup_collage_link(host_collage = nil, linked_collage = nil)
    @collage_link = CollageLink.new
    @collage_link.link_text_start = "T1"
    @collage_link.link_text_end = "T2"
    @collage_link.host_collage = host_collage if host_collage
    @collage_link.linked_collage = linked_collage if linked_collage
    @collage_link.save!
  end

  def setup_user(name = 'testuser')
    @user = User.create!(:login => name)
    @user
  end

  def setup_role
    @role = Role.create!(:name => 'creators')
  end

  def setup_h2ocases_user
    u = User.new(:login => 'h2ocases',
                 :email_address => 'h2ocases@harvard.edu',
                 :password => 'password',
                 :password_confirmation => 'password')
    u.save false

  end
end
