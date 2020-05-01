require 'open_food_network/error_logger'

class UserRegistrationsController < Spree::UserRegistrationsController
  I18N_SCOPE = 'devise.user_registrations.spree_user'.freeze

  before_filter :set_checkout_redirect, only: :create

  include I18nHelper
  before_filter :set_locale

  # POST /resource/sign_up
  def create
    @user = build_resource(params[:spree_user])
    @user.locale = I18n.locale.to_s
    unless resource.save
      return render_error(@user.errors)
    end

    session[:spree_user_signup] = true
    session[:confirmation_return_url] = params[:return_url]
    associate_user

    respond_to do |format|
      format.js do
        render json: { email: @user.email }
      end
    end
  rescue StandardError => e
    OpenFoodNetwork::ErrorLogger.notify(e)
    render_error(message: I18n.t('unknown_error', scope: I18N_SCOPE))
  end

  private

  def render_error(errors = {})
    clean_up_passwords(resource)
    respond_to do |format|
      format.js do
        render json: errors, status: :unauthorized
      end
    end
  end
end
