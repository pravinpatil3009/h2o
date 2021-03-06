class CasesController < BaseController
  cache_sweeper :case_sweeper

  caches_page :show
  before_filter :require_user, :except => [:index, :show, :metadata, :embedded_pager, :export, :access_level]
  before_filter :load_single_resource, :only => [:show, :edit, :update, :destroy, :export, :approve, :access_level]

  # Only admin can edit cases - they must remain pretty much immutable, otherwise annotations could get
  # messed up in terms of location.

  access_control do
    allow all, :to => [:show, :index, :metadata, :autocomplete_tags, :new, :create,
                       :embedded_pager, :export, :access_level, :upload]

    allow logged_in, :to => [:destroy, :edit, :update], :if => :is_owner?

    allow :case_admin, :superadmin
  end

  def autocomplete_tags
    render :json => Case.autocomplete_for(:tags,params[:tag])
  end

  def metadata
    #FIXME
  end

  def embedded_pager
    super Case
  end

  # GET /cases
  def index
    common_index Case
  end

  # GET /cases/1
  def show
    @page_cache = true
    @editability_path = access_level_case_path(@case)

    add_javascripts 'cases'
    set_belongings Case

    if !@case.public || !@case.active
      flash[:notice] = "This case is not public or active."
      redirect_to cases_url
    end
  end

  def access_level
    if current_user
      render :json => {
        :can_edit => @case.can_edit?,
        :custom_block => 'case_afterload'
      }
    else
      render :json => {
        :can_edit => false,
        :custom_block => 'case_afterload'
      }
    end
  end

  def export
    render :layout => 'print'
  end

  def approve
    approve_case! @case
    render :json => {}
  end

  # GET /cases/new
  def new
    @case = Case.new
    if params.has_key?(:case_request_id)
      case_request = CaseRequest.find(params[:case_request_id])
      @case.case_request = case_request

      [:full_name, :decision_date, :author, :case_jurisdiction].each do |f|
        @case.send("#{f}=", case_request.send(f))
      end
      case_docket_number = CaseDocketNumber.new(:docket_number => case_request.docket_number)
      @case.case_docket_numbers = [case_docket_number]
      @case.case_citations << CaseCitation.new(:reporter => case_request.reporter,
                                               :volume => case_request.volume,
                                               :page => case_request.page)
    else
      @case.case_jurisdiction = CaseJurisdiction.new
    end

    add_javascripts ['h2o_wysiwig', 'switch_editor', 'cases']
    add_stylesheets ['new_case']
  end

  def upload
    if request.get?
      add_javascripts ['h2o_wysiwig', 'switch_editor', 'cases']
      add_stylesheets ['new_case']

      respond_to do |format|
        format.html { render :template => 'cases/upload'}
        format.xml  { render :xml => @case }
      end
    else
      @case = Case.new_from_xml_file(params[:file])
      if @case.save
        handle_successful_save
      else
        flash[:notice] = @case.errors.full_messages.join(", ")
        render :template => "cases/upload"
      end
    end
  end

  # GET /cases/1/edit
  def edit
    add_javascripts ['h2o_wysiwig', 'switch_editor', 'cases']
    add_stylesheets ['new_case']
  end

  # POST /cases
  def create
    unless params[:case][:tag_list].blank?
      params[:case][:tag_list] = params[:case][:tag_list].downcase
    end
    @case = Case.new(params[:case])

    add_javascripts ['h2o_wysiwig', 'switch_editor', 'cases']
    add_stylesheets ['new_case']

    if @case.save
      approve_case! @case if params[:commit][/APPROVE/]
      handle_successful_save
    else
      render :action => "new"
    end
  end

  # PUT /cases/1
  def update
    # This is not industrial level security - a user could theoretically overwrite the case content of a case they own via URL tampering.
    unless params[:case][:tag_list].blank?
      params[:case][:tag_list] = params[:case][:tag_list].downcase
    end
    add_javascripts ['h2o_wysiwig', 'switch_editor', 'cases']
    add_stylesheets ['new_case']

    @case.updated_at = Time.now #<=This ensures that version is incremented when docket numbers or citations are only updated
    if @case.update_attributes(params[:case])
      approve_case! @case if params[:commit][/APPROVE/]
      if @case.active
        Notifier.deliver_case_notify_updated(@case)
        flash[:notice] = 'Case was successfully updated.'
        redirect_to "/cases/#{@case.id}"
      else
        flash[:notice] = 'Case was successfully updated. It must be approved before it is visible.'
        redirect_to "/users/#{current_user.id}\#p_pending_cases"
      end
    else
      render :action => "edit"
    end
  end

  # DELETE /cases/1
  def destroy
    Notifier.deliver_case_notify_rejected(@case)
    @case.destroy
    render :json => {}
  end

  private
  def approve_case!(_case)
    _case.approve!
    Notifier.deliver_case_notify_approved(_case)
  end

  def handle_successful_save
    @case.case_request.approve! if @case.case_request
    if @case.active
      Notifier.deliver_case_notify_approved(@case)
      flash[:notice] = 'Case was successfully created.'
      redirect_to "/cases/#{@case.id}"
    else
      flash[:notice] = 'Case was successfully created. It must be approved before it is visible.'
      redirect_to cases_url
    end
  end
end
