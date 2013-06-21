module CasesHelper
  def path_to_case_or_case_version(options = {})
    case_obj = options[:case].original || options[:case]
    case_version = options[:case_version]

    if case_obj.version == case_version.version
      case_path(case_obj)
    else
      case_version_path(case_obj, case_version.version)
    end
  end

  def can_edit_this_case?
    (current_user.is_case_admin || current_user.cases.include?(@case))
  end

end
