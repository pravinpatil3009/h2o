require File.dirname(__FILE__) + '/../../test_helper'

class CaseTest < ActiveSupport::TestCase
  def setup
    setup_h2ocases_user
    setup_case
  end

  def test_version_of_newly_created_is_one
    assert_equal 1, @case.version
  end

  def test_version_incrementing
    @case.short_name = "two"
    @case.save!
    @case.short_name = "three"
    @case.save!
    @case.short_name = "four"
    @case.save!
    @case.short_name = "five"
    assert_equal 4, @case.reload.version
  end

  def test_should_have_a_versioned_class
    assert_equal Case::Version, Case.versioned_class
  end

  def test_should_have_a_version_column
    assert_equal 'version', Case.version_column
  end

  def test_can_set_case_jurisdiction_version
    @case.case_jurisdiction_version = 5
    @case.save!
    @case.reload
    assert_equal 5, @case.case_jurisdiction_version
  end

  def test_version_number_increments
    @case.content = "new content"
    @case.save!
    assert_equal 2, @case.version
  end

  def test_version_count_increments
    assert_equal 1, @case.versions.count
    @case.content = "new content"
    @case.save!
    assert_equal 2, @case.versions.count
  end

  def test_can_get_old_revision_content
    @case.content = "new content"
    @case.save!
    assert_equal 'first_content', @case.versions.find_by_version(1).content
  end

  def test_find_by_version_releases_a_case_version_class
    @case.content = "new_content"
    @case.save!
    assert_equal Case::Version, @case.versions.find_by_version(1).class
  end

  def test_copy_by_id_and_version_returns_case_class
    @case.content = "new_content"
    @case.save!
    assert_equal Case, Case.copy_by_id_and_version(@case.id, 1).class
  end

  def test_copy_by_id_and_version_returns_correct_version
    @case.content = "new_content"
    @case.save!
    assert_equal 'first_content', Case.copy_by_id_and_version(@case.id, 1).content
  end

  def test_that_copy_flag_set_on_copy
    @case.content = "new_content"
    @case.save!
    new_case = Case.copy_by_id_and_version(@case.id, 1)
    assert new_case.copy?
  end

  def test_copy_id_is_same_as_case_id
    @case.content = "new_content"
    @case.save!
    new_case = Case.copy_by_id_and_version(@case.id, 1)
    assert_equal @case.id, new_case.id
  end

  def test_before_add_callback_is_added
    assert_equal [:set_annotatable_version], Case.read_inheritable_attribute(:before_add_for_collages)
  end

  def test_annotatable_version_is_being_set
    setup_collage
    @case.collages << @collage
    assert_equal 1, @collage.annotatable_version
  end

  def test_collages_still_returns_original_collage
    setup_collage
    @case.collages << @collage
    assert_equal [@collage], @case.collages
  end

  def test_collages_will_return_a_copy_from_a_copy
    setup_collage
    @case.collages << @collage
    @case.content = "new_content"
    @case.save!
    new_case = Case.copy_by_id_and_version(@case.id, 1)
    assert_equal 1, new_case.collages.count
  end

  def test_two_versioned_collages_returned
    setup_collage
    @case.collages << @collage
    setup_collage('second', 'second')
    @case.collages << @collage
    @case.save!
    new_case = Case.copy_by_id_and_version(@case.id, 1)

    assert_equal 2, new_case.collages.count
    @case.short_name = "bada bing"
    @case.save!
    new_case = Case.copy_by_id_and_version(@case.id, 2)
    assert_equal 2, new_case.collages.count


  end

  def test_two_versioned_collages_with_changes_in_one_version
    assert_equal 1, @case.version
    Collage::Version.destroy_all
    setup_collage
    @case.collages << @collage
    setup_collage('second', 'second')
    @case.collages << @collage
    @case.short_name = "bada bing"

    assert_equal 1, @case.collages.first.annotatable_version
    assert_equal 1, @case.collages.last.annotatable_version

    @case.save!
    assert_equal 2, @case.version
    collage_one = @case.collages.first
    collage_two = @case.collages.last
    assert_equal 2, collage_one.annotatable_version
    assert_equal 2, collage_two.annotatable_version
    collage_one.update_attribute('content', "foo bar")
    collage_two.update_attribute('content', 'yadda yadda yadda')
    @case.short_name = "New Name Now"
    @case.save!
    assert_equal 3, collage_one.annotatable_version
    assert_equal 3, collage_one.versions.last.annotatable_version
    assert_equal 3, collage_two.annotatable_version
    new_case = Case.copy_by_id_and_version(@case.id, 1)
    assert_equal  2, new_case.collages.count
    assert_equal 'first', new_case.collages.first.content
  end

  def test_version_copy_still_returns_versions
    @case.short_name = "first"
    @case.save!
    @case.short_name = "second"
    @case.save!
    assert_equal 3, @case.versions.count
    new_case = Case.copy_by_id_and_version(@case.id, 1)
    assert_equal @case.versions.first, new_case.versions.first
  end

  def test_copy_has_a_pointer_back_to_the_original
    @case.short_name = "first"
    @case.save!
    @case.short_name = "second"
    @case.save!
    assert_equal 3, @case.versions.count
    new_case = Case.copy_by_id_and_version(@case.id, 1)
    assert_equal @case, new_case.original
    assert_equal 3, new_case.original.versions.count
  end

  def test_multiple_versions_of_case_jurisdiction
    setup_case_jurisdiction
    @case_jurisdiction.cases << @case
    @case_jurisdiction.name = "Newton"
    @case_jurisdiction.save!
    @case.reload
    assert_equal 2, @case.case_jurisdiction_version
    new_case = Case.copy_by_id_and_version(@case.id, 2)
    assert_equal "first", new_case.case_jurisdiction.name
    @case.content = "new content"
    @case.save!
    new_case = Case.copy_by_id_and_version(@case.id, 3)
    assert_equal "Newton", new_case.case_jurisdiction.name
  end

  def test_original_case_jurisdiction_works_normally
    setup_case_jurisdiction
    @case_jurisdiction.cases << @case
    @case_jurisdiction.name = "Newton"
    @case_jurisdiction.save!
    @case.reload
    assert_equal @case_jurisdiction, @case.case_jurisdiction
  end

  def test_copy_cannot_be_updated
    setup_case
    new_case = Case.copy_by_id_and_version(@case, 1)
    new_case.short_name = "new name"
    assert_raise(RuntimeError) {  new_case.save!}
  end

  def test_respond_to_creators
    assert_respond_to Case.new, :creators
  end

  def test_respond_to_shallow_copy
    assert_respond_to Case, :shallow_copy
  end

  def test_has_versioned_associations
    assert Case.respond_to?(:versioned_associations)
  end

  def test_versioned_associations_returns_has_many_relationships_by_default
    assert_equal :has_many, Case.versioned_associations.first.macro
  end

  def test_versioned_associations_returns_belongs_to_if_passed_in
    assert_equal :belongs_to, Case.versioned_associations(:belongs_to).first.macro
  end

  def test_versioned_associations_rejects_version_associations_added_by_acts_as_versioned
    assert !Case.versioned_associations.map{|a| a.name}.include?(:versions)
  end

  def test_versioned_associations_rejects_has_many_through_relationships
    assert !Case.versioned_associations.any?{|a| a.options.has_key?(:through)}
  end

  def test_respond_to_has_many_versioned_associations
    assert Case.respond_to?(:has_many_versioned_associations)
  end

  def test_respond_to_belongs_to_has_many_versioned_associations
    assert Case.respond_to?(:belongs_to_versioned_associations)
  end

  def test_respond_to_seed_update_sql
    assert_respond_to Case, :seed_update_sql
  end

  def test_seed_update_sql
    assert_equal 'UPDATE cases SET case_jurisdiction_version=1, case_request_version=1, version=1;', Case.seed_update_sql
  end

  def setup_h2ocases_user
    u = User.new(:login => 'h2ocases',
                 :email_address => 'h2ocases@harvard.edu',
                 :password => 'password',
                 :password_confirmation => 'password')
    u.save false

  end
end
