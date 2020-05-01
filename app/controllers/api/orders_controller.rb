module Api
  class OrdersController < Api::BaseController
    def show
      authorize! :read, order
      render json: order, serializer: Api::OrderDetailedSerializer, current_order: order
    end

    def index
      authorize! :admin, Spree::Order

      search_results = SearchOrders.new(params, spree_current_user)

      render json: {
        orders: serialized_orders(search_results.orders),
        pagination: search_results.pagination_data
      }
    end

    def ship
      authorize! :admin, order

      if order.ship
        render json: order.reload, serializer: Api::Admin::OrderSerializer, status: :ok
      else
        render json: { error: I18n.t('api.orders.failed_to_update') }, status: :unprocessable_entity
      end
    end

    def capture
      authorize! :admin, order

      pending_payment = order.pending_payments.first

      return payment_capture_failed unless order.payment_required? && pending_payment

      if pending_payment.capture!
        render json: order.reload, serializer: Api::Admin::OrderSerializer, status: :ok
      else
        payment_capture_failed
      end
    rescue Spree::Core::GatewayError => e
      error_during_processing(e)
    end

    private

    def payment_capture_failed
      render json: { error: t(:payment_processing_failed) }, status: :unprocessable_entity
    end

    def serialized_orders(orders)
      ActiveModel::ArraySerializer.new(
        orders,
        each_serializer: Api::Admin::OrderSerializer
      )
    end

    def order
      @order ||= Spree::Order.
        where(number: params[:id]).
        includes(line_items: { variant: [:product, :stock_items, :default_price] }).
        first!
    end
  end
end
