module Spree
  class UserSessionsController < Devise::SessionsController
    helper 'spree/base', 'spree/store'

    include Spree::Core::ControllerHelpers::Auth
    include Spree::Core::ControllerHelpers::Common
    include Spree::Core::ControllerHelpers::Order
    include Spree::Core::ControllerHelpers::SSL

    ssl_required :new, :create, :destroy, :update
    ssl_allowed :login_bar

    before_filter :set_checkout_redirect, only: :create

    def create
      authenticate_spree_user!

      if spree_user_signed_in?
        respond_to do |format|
          format.html {
            flash[:success] = t('devise.success.logged_in_succesfully')
            redirect_back_or_default(after_sign_in_path_for(spree_current_user))
          }
          format.js {
            render json: { email: spree_current_user.login }, status: :ok
          }
        end
      else
        respond_to do |format|
          format.html {
            flash.now[:error] = t('devise.failure.invalid')
            render :new
          }
          format.js {
            render json: { message: t('devise.failure.invalid') }, status: :unauthorized
          }
        end
      end
    end

    private

    def accurate_title
      Spree.t(:login)
    end

    def redirect_back_or_default(default)
      redirect_to(session["spree_user_return_to"] || default)
      session["spree_user_return_to"] = nil
    end
  end
end
