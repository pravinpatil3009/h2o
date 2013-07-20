require File.dirname(__FILE__) + '/../../test_helper'

class AnnotationTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  #test "the truth" do
    #assert true
  #end
  def setup
    setup_case
    setup_collage
    setup_annotation
  end

  test "respond to shallow copy" do
    assert_respond_to Annotation, :shallow_copy
  end

  test "annotations support versions" do
    assert Annotation.respond_to?(:create_versioned_table)
  end

  test "annotation tracks collage version" do

    @collage.annotations << @annotation
    assert_equal 2, @annotation.collage_version
  end

  test "annotation does not add case callbacks based on the has many through relation of case to annotations" do
    assert !@annotation.respond_to?(:update_case_version)
  end

  def test_should_return_one_annotation_for_the_collage
    Collage.destroy_all
    Annotation.destroy_all
    collage = setup_collage
    assert_equal 0, collage.annotations.count
    annotation = setup_annotation(:collage => collage)
    assert_equal 1, collage.annotations.count
    collage.reload
    assert_equal [annotation], collage.annotations
  end

  def test_create_an_annotation_causes_collage_version_increment
    assert_equal 1, @collage.version
    assert_equal 1, @collage.annotations.count
    @collage.reload
    assert_equal 2, @collage.version
    annotation = @collage.annotations.build(:annotation_start => 'T1',
                                            :annotation_end => 'T2',
                                            :annotation => 'My New Annotation',
                                            :annotated_content => 'end'
                                           )
    annotation.save!
    @collage.reload
    assert_equal 2, @collage.annotations.count
    @collage.reload
    assert_equal 3, @collage.version

  end

end
