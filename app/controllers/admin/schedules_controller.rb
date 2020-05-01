require 'open_food_network/permissions'
require 'order_management/subscriptions/proxy_order_syncer'

module Admin
  class SchedulesController < ResourceController
    before_filter :check_editable_order_cycle_ids, only: [:create, :update]
    before_filter :check_dependent_subscriptions, only: [:destroy]
    create.after :sync_subscriptions
    update.after :sync_subscriptions

    respond_to :json

    respond_override create: { json: {
      success: lambda { render_as_json @schedule, editable_schedule_ids: permissions.editable_schedules.pluck(:id) },
      failure: lambda { render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity }
    } }
    respond_override update: { json: {
      success: lambda { render_as_json @schedule, editable_schedule_ids: permissions.editable_schedules.pluck(:id) },
      failure: lambda { render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity }
    } }

    def index
      respond_to do |format|
        format.json do
          render_as_json @collection, ams_prefix: params[:ams_prefix], editable_schedule_ids: permissions.editable_schedules.pluck(:id)
        end
      end
    end

    private

    def collection
      return Schedule.where("1=0") unless json_request?

      if params[:enterprise_id]
        filter_schedules_by_enterprise_id(permissions.visible_schedules, params[:enterprise_id])
      else
        permissions.visible_schedules
      end
    end

    # Filter schedules by OCs with a given coordinator id
    def filter_schedules_by_enterprise_id(schedules, enterprise_id)
      schedules.joins(:order_cycles).where(order_cycles: { coordinator_id: enterprise_id.to_i })
    end

    def collection_actions
      [:index]
    end

    def check_editable_order_cycle_ids
      return unless params[:schedule][:order_cycle_ids]

      requested = params[:schedule][:order_cycle_ids]
      @existing_order_cycle_ids = @schedule.persisted? ? @schedule.order_cycle_ids : []
      permitted = OrderCycle.where(id: params[:schedule][:order_cycle_ids] | @existing_order_cycle_ids).merge(OrderCycle.managed_by(spree_current_user)).pluck(:id)
      result = @existing_order_cycle_ids
      result |= (requested & permitted) # add any requested & permitted ids
      result -= ((result & permitted) - requested) # remove any existing and permitted ids that were not specifically requested
      params[:schedule][:order_cycle_ids] = result
      @object.order_cycle_ids = result
    end

    def check_dependent_subscriptions
      return if Subscription.where(schedule_id: @schedule).empty?

      render json: { errors: [t('admin.schedules.destroy.associated_subscriptions_error')] }, status: :conflict
    end

    def permissions
      return @permissions unless @permission.nil?

      @permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    end

    def sync_subscriptions
      return unless params[:schedule][:order_cycle_ids]

      removed_ids = @existing_order_cycle_ids - @schedule.order_cycle_ids
      new_ids = @schedule.order_cycle_ids - @existing_order_cycle_ids
      return unless removed_ids.any? || new_ids.any?

      subscriptions = Subscription.where(schedule_id: @schedule)
      syncer = OrderManagement::Subscriptions::ProxyOrderSyncer.new(subscriptions)
      syncer.sync!
    end
  end
end
