require 'spec_helper'

feature "Authentication", js: true do
  include UIComponentHelper
  include OpenFoodNetwork::EmailHelper

  describe "login" do
    let(:user) { create(:user, password: "password", password_confirmation: "password") }

    describe "With redirects" do
      scenario "logging in with a redirect set" do
        visit groups_path(anchor: "login?after_login=#{producers_path}")
        fill_in "Email", with: user.email
        fill_in "Password", with: user.password
        click_login_button
        expect(page).to have_content "Find local producers"
        expect(page).to have_current_path producers_path
      end
    end

    describe "Loggin in from the home page" do
      before do
        visit root_path
      end
      describe "as large" do
        before do
          browse_as_large
          open_login_modal
        end
        scenario "showing login" do
          expect(page).to have_login_modal
        end

        scenario "failing to login" do
          fill_in "Email", with: user.email
          click_login_button
          expect(page).to have_content "Invalid email or password"
        end

        scenario "logging in successfully" do
          fill_in "Email", with: user.email
          fill_in "Password", with: user.password
          click_login_button
          expect(page).to be_logged_in_as user
        end

        describe "signing up" do
          before do
            select_login_tab "Sign up"
          end

          scenario "Failing to sign up because password is too short" do
            fill_in "Email", with: "test@foo.com"
            fill_in "Choose a password", with: "short"
            click_signup_button
            expect(page).to have_content "too short"
          end

          scenario "Failing to sign up because email is already registered" do
            fill_in "Email", with: user.email
            fill_in "Choose a password", with: "foobarino"
            click_signup_button
            expect(page).to have_content "There's already an account for this email."
          end

          scenario "Failing to sign up because password confirmation doesn't match or is blank" do
            fill_in "Email", with: user.email
            fill_in "Choose a password", with: "ForgotToRetype"
            click_signup_button
            expect(page).to have_content "doesn't match"
          end

          scenario "Signing up successfully" do
            performing_deliveries do
              setup_email
              fill_in "Email", with: "test@foo.com"
              fill_in "Choose a password", with: "test12345"
              fill_in "Confirm password", with: "test12345"

              expect do
                click_signup_button
                expect(page).to have_content I18n.t('devise.user_registrations.spree_user.signed_up_but_unconfirmed')
              end.to send_confirmation_instructions
            end
          end
        end

        describe "forgetting passwords" do
          before do
            ActionMailer::Base.deliveries.clear
            select_login_tab "Forgot Password?"
          end

          scenario "failing to reset password" do
            fill_in "Your email", with: "notanemail@myemail.com"
            click_reset_password_button
            expect(page).to have_content "Email address not found"
          end

          scenario "resetting password" do
            fill_in "Your email", with: user.email
            expect do
              click_reset_password_button
              expect(page).to have_reset_password
            end.to enqueue_job Delayed::PerformableMethod
            expect(Delayed::Job.last.payload_object.method_name).to eq(:send_reset_password_instructions_without_delay)
          end
        end
      end
      describe "as medium" do
        before do
          browse_as_medium
        end
        after do
          browse_as_large
        end
        scenario "showing login" do
          open_off_canvas
          open_login_modal
          expect(page).to have_login_modal
        end
      end
    end

    describe "after following email confirmation link" do
      scenario "shows confirmed message in modal" do
        visit '/#/login?validation=confirmed'
        expect(page).to have_login_modal
        expect(page).to have_content I18n.t('devise.confirmations.confirmed')
      end
    end

    scenario "Loggin by typing login/ redirects to /#/login" do
      visit "/login"
      uri = URI.parse(current_url)
      expect(uri.path + "#" + uri.fragment).to eq('/#/login')
    end
  end
end
