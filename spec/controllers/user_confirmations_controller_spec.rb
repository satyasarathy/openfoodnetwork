require 'spec_helper'

describe UserConfirmationsController, type: :controller do
  include AuthenticationWorkflow
  include OpenFoodNetwork::EmailHelper

  let!(:user) { create_enterprise_user }
  let!(:confirmed_user) { create_enterprise_user(confirmed_at: nil) }
  let!(:unconfirmed_user) { create_enterprise_user(confirmed_at: nil) }
  let!(:confirmed_token) { confirmed_user.confirmation_token }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
    confirmed_user.confirm!
  end

  context "confirming a user" do
    context "that has already been confirmed" do
      before do
        spree_get :show, confirmation_token: confirmed_token
      end

      it "redirects the user to login" do
        expect(response).to redirect_to login_path(validation: 'not_confirmed')
      end
    end

    context "that has not been confirmed" do
      it "confirms the user" do
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(unconfirmed_user.reload.confirmed_at).not_to eq(nil)
      end

      it "redirects the user to #/login by default" do
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(response).to redirect_to login_path(validation: 'confirmed')
      end

      it "redirects to previous url, if present" do
        session[:confirmation_return_url] = producers_path + '#/login'
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(response).to redirect_to producers_path + '#/login?validation=confirmed'
      end

      it "redirects to previous url on /register path" do
        session[:confirmation_return_url] = registration_path + '#/signup?after_login=%2Fregister'
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(response).to redirect_to registration_path + '#/signup?after_login=%2Fregister&validation=confirmed'
      end

      it "redirects to set password page, if user needs to reset their password" do
        unconfirmed_user.reset_password_token = Devise.friendly_token
        unconfirmed_user.save!
        spree_get :show, confirmation_token: unconfirmed_user.confirmation_token
        expect(response).to redirect_to spree.edit_spree_user_password_path(reset_password_token: unconfirmed_user.reset_password_token)
      end
    end
  end

  context "requesting confirmation instructions to be resent" do
    before { setup_email }

    it "redirects the user to login" do
      spree_post :create, spree_user: { email: unconfirmed_user.email }
      expect(response).to redirect_to login_path
      expect(flash[:success]).to eq I18n.t('devise.user_confirmations.spree_user.confirmation_sent')
    end

    it "sends the confirmation email" do
      performing_deliveries do
        expect do
          spree_post :create, spree_user: { email: unconfirmed_user.email }
        end.to send_confirmation_instructions
      end
    end
  end
end
