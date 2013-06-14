require File.dirname(__FILE__) + '/../../test_helper'

class CaseJurisdictionTest < ActiveSupport::TestCase
  def setup
    setup_case_jurisdiction
    setup_case
  end

  def test_has_version_one_for_first_save
    assert_equal 1, @case_jurisdiction.version
  end

  test "responds to versions" do
    assert_respond_to CaseJurisdiction.new, :versions
  end

  def test_that_updating_case_jurisidiction_updates_cases_version
    @case_jurisdiction.cases << @case
    @case.reload
    assert_equal 1, @case.case_jurisdiction_version
  end

  def test_updating_case_jurisdiction_also_updates_case_version
    @case_jurisdiction.cases << @case
    @case_jurisdiction.name = "Newton"
    @case_jurisdiction.save!
    @case.reload
    assert_equal 2, @case.case_jurisdiction_version
  end

end
