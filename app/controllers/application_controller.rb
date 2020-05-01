require 'open_food_network/referer_parser'
require_dependency 'spree/authentication_helpers'

class ApplicationController < ActionController::Base
  protect_from_forgery

  prepend_before_filter :restrict_iframes
  before_filter :set_cache_headers # prevent cart emptying via cache when using back button #1213

  include EnterprisesHelper
  include Spree::AuthenticationHelpers

  def redirect_to(options = {}, response_status = {})
    ::Rails.logger.error("Redirected by #{begin
                                            caller(1).first
                                          rescue StandardError
                                            'unknown'
                                          end}")
    super(options, response_status)
  end

  def set_checkout_redirect
    referer_path = OpenFoodNetwork::RefererParser.path(request.referer)
    if referer_path
      is_checkout_path_the_referer = [main_app.checkout_path].include?(referer_path)
      session["spree_user_return_to"] = if is_checkout_path_the_referer
                                          referer_path
                                        else
                                          main_app.root_path
                                        end
    end
  end

  def shopfront_session
    session[:safari_fix] = true
    render 'shop/shopfront_session', layout: false
  end

  def enable_embedded_styles
    session[:embedded_shopfront] = true
    render json: {}, status: :ok
  end

  def disable_embedded_styles
    session.delete :embedded_shopfront
    session.delete :shopfront_redirect
    render json: {}, status: :ok
  end

  protected

  def after_sign_in_path_for(resource_or_scope)
    return session[:shopfront_redirect] if session[:shopfront_redirect]

    stored_location_for(resource_or_scope) || main_app.root_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    session[:shopfront_redirect] || main_app.root_path
  end

  private

  def restrict_iframes
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['Content-Security-Policy'] = "frame-ancestors 'none'"
  end

  def enable_embedded_shopfront
    embed_service = EmbeddedPageService.new(params, session, request, response)
    embed_service.embed!
    @shopfront_layout = 'embedded' if embed_service.use_embedded_layout?
  end

  def action
    params[:action].to_sym
  end

  def require_distributor_chosen
    unless @distributor = current_distributor
      redirect_to main_app.root_path
      false
    end
  end

  def require_order_cycle
    unless current_order_cycle
      redirect_to main_app.shop_path
    end
  end

  def check_hub_ready_for_checkout
    if current_distributor_closed?
      current_order.empty!
      current_order.set_distribution! nil, nil
      flash[:info] = "The hub you have selected is temporarily closed for orders. "\
        "Please try again later."
      redirect_to main_app.root_url
    end
  end

  def current_distributor_closed?
    current_distributor &&
      current_order &&
      current_distributor.respond_to?(:ready_for_checkout?) &&
      !current_distributor.ready_for_checkout?
  end

  def check_order_cycle_expiry
    if current_order_cycle.andand.closed?
      session[:expired_order_cycle_id] = current_order_cycle.id
      current_order.empty!
      current_order.set_order_cycle! nil
      flash[:info] = "The order cycle you've selected has just closed. Please try again!"
      redirect_to main_app.root_url
    end
  end

  # All render calls within the block will be performed with the specified format
  # Useful for rendering html within a JSON response, particularly if the specified
  # template or partial then goes on to render further partials without specifying
  # their format.
  def with_format(format)
    old_formats = formats
    self.formats = [format]
    yield
    self.formats = old_formats
    nil
  end

  def set_cache_headers # https://jacopretorius.net/2014/01/force-page-to-reload-on-browser-back-in-rails.html
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
