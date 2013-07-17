require File.dirname(__FILE__) + '/../../test_helper'

class CollageTest < ActiveSupport::TestCase
  def setup
    setup_case
    setup_collage
  end

  def test_collage_should_respond_to_copy_by_id_and_version
    assert_respond_to Collage, :copy_by_id_and_version
  end

  def test_collage_should_respond_to_copy
    assert_respond_to Collage.new, :copy?
  end

  def test_should_respond_to_versions
    assert Collage.new.versions
  end

  def test_save_does_not_save_annotatable_version_if_no_case
    assert_equal 1, @collage.annotatable_version
  end


  def test_saving_case_should_update_the_collage_annotatable_version
    @case.collages << @collage
    @case.content = "second content"
    @case.save!
    assert_equal 2, @case.version
    @collage.reload
    assert_equal 2, @collage.annotatable_version
    #@case.content = "third content"
    #@case.save!
    #assert_equal 3, @collage.annotatable_version
  end

  def test_collage_added_to_case_without_explicit_save
    assert_equal 1, @collage.annotatable_version
    @case.save!
    assert_equal 1, @collage.annotatable_version
    assert_equal @case.id, @collage.annotatable_id
  end

  def test_can_get_most_recent_edit_when_there_are_multiple_edits
    @case.collages << @collage
    assert_equal 1, @case.collages.count
    assert_equal 1, @case.version
    assert_equal 1, @case.collages.first.annotatable_version
    @collage.content = "collage second content"
    @collage.save!

    @collage.content = "collage third content"
    @collage.save!

    @case.content = "second_content"
    @case.save!
    assert_equal "collage third content", @collage.versions.find(:last, :conditions => ['annotatable_version = ?', 1]).content
  end

  def test_collage_with_multiple_saves
    assert_equal 1, @collage.version
    @case.collages << @collage
    assert_equal 1, @case.collages.count
    assert_equal 1, @case.version
    assert_equal 1, @case.collages.first.annotatable_version
    @collage.content = "collage second content"
    @collage.save!

    @collage.content = "collage third content"
    @collage.save!

    @case.content = "second_content"
    @case.save!
    collage = Collage.copy_by_id_and_version(@collage.id, 2)
    new_case = Case.copy_by_id_and_version(@case.id, 1)
    assert_equal new_case.content, collage.annotatable.content

  end

end


