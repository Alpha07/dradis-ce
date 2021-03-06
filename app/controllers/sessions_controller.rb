# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  before_action :ensure_setup,          only: :new
  before_action :ensure_not_setup,      only: [:init, :setup]
  before_action :ensure_valid_password, only: :setup

  # ------------------------------------------- Initial shared password setup
  # Initialise the session, clear any objects that might currently exist and
  # present the session start up configuration HTML form.
  #
  # GET /setup
  def init
    # We overwrite the default "access denied" message set by AuthenticatedController
    flash[:alert] = 'Hold your horses!'
  end

  # POST /setup
  #
  # @password was set by the ensure_valid_password filter
  def setup
    setting       = ::Configuration.find_by_name('admin:password')
    setting.value = ::BCrypt::Password.create(@password)

    if setting.save
      flash[:notice] = 'All done. May the findings for this project be plentiful!'
    else
      flash[:alert] = "Something went wrong: #{setting.errors.full_messages.join('; ')}"
    end

    redirect_to action: :new
  end
  # ------------------------------------------ /Initial shared password setup

  def new
    flash.now[:alert] = warden_message if warden_message.present?
  end

  def create
    warden.authenticate!
    redirect_to_target_or_default root_url
  end

  def destroy
    logout
    redirect_to login_path, notice: 'You have been logged out.'
  end

  protected

  # Only allow access to the setup actions if we still don't have a valid
  # shared password.
  def ensure_not_setup
    redirect_to action: :new unless (::Configuration.shared_password == 'improvable_dradis')
  end

  # If the database doesn't contain a valid password, a new one needs to be
  # created.
  def ensure_setup
    if (::Configuration.shared_password == 'improvable_dradis')
      redirect_to setup_path
    end
  end


  # Ensure that the user has provided a valid password, that the password
  # matches the confirmation and that they are not empty.
  #
  # FIXME: we should move this to a form object.
  # See:
  #   http://railscasts.com/episodes/416-form-objects
  #
  def ensure_valid_password
    # Step 1:  Password and Password confirmation match
    pwd1 = params.fetch(:password, nil)
    pwd2 = params.fetch(:password_confirmation, nil)

    if (pwd1.nil? || pwd2.nil? || pwd1.blank?)
      flash[:alert] = 'You need to provide both a password and a confirmation.'
      render :init
      return false
    end

    if not pwd1 == pwd2
      flash[:alert] = 'The password did not match the confirmation.'
      render :init
      return false
    end

    @password = pwd1
    return true
  end
end
