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
    assert_equal 1, @annotation.collage_version
  end

  test "annotation does not add case callbacks based on the has many through relation of case to annotations" do
    assert !@annotation.respond_to?(:update_case_version)
  end


end
