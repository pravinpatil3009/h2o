require File.dirname(__FILE__) + '/../../test_helper'

class CollageLinkTest < ActiveSupport::TestCase

  def setup
    setup_case
  end

  def test_collage_copy_responds_to_collage_links
    setup_collage
    @collage.save!
    new_copy = Collage.copy_by_id_and_version(@collage, 1)
    assert_respond_to new_copy, :collage_links
  end

  def test_collage_copy_returns_collage_link_for_a_version
    first_collage = setup_collage('first', 'first', true)
    second_collage = setup_collage('second', 'second', true)
    setup_collage_link(first_collage, second_collage)
    assert_equal 3, @collage_link.host_collage_version
    assert_equal 1, @collage_link.linked_collage_version
    assert_equal @collage_link.link_text_start, Collage.copy_by_id_and_version(first_collage.id, 3).collage_links.first.link_text_start
  end

end
