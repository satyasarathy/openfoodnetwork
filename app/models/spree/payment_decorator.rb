require 'spree/localized_number'

module Spree
  Payment.class_eval do
    extend Spree::LocalizedNumber

    delegate :line_items, to: :order

    has_one :adjustment, as: :source, dependent: :destroy

    after_save :ensure_correct_adjustment, :update_order

    attr_accessible :source

    localize_number :amount

    def ensure_correct_adjustment
      revoke_adjustment_eligibility if ['failed', 'invalid'].include?(state)
      return if adjustment.try(:finalized?)

      if adjustment
        adjustment.originator = payment_method
        adjustment.label = adjustment_label
        adjustment.save
      else
        payment_method.create_adjustment(adjustment_label, order, self, true)
        association(:adjustment).reload
      end
    end

    def adjustment_label
      I18n.t('payment_method_fee')
    end

    # Pin payments lacks void and credit methods, but it does have refund
    # Here we swap credit out for refund and remove void as a possible action
    def actions_with_pin_payment_adaptations
      actions = actions_without_pin_payment_adaptations
      if payment_method.is_a? Gateway::Pin
        actions << 'refund' if actions.include? 'credit'
        actions.reject! { |a| ['credit', 'void'].include? a }
      end
      actions
    end
    alias_method_chain :actions, :pin_payment_adaptations

    def refund!(refund_amount = nil)
      protect_from_connection_error do
        check_environment

        refund_amount = calculate_refund_amount(refund_amount)

        if payment_method.payment_profiles_supported?
          response = payment_method.refund((refund_amount * 100).round, source, response_code, gateway_options)
        else
          response = payment_method.refund((refund_amount * 100).round, response_code, gateway_options)
        end

        record_response(response)

        if response.success?
          self.class.create({ order: order,
                              source: self,
                              payment_method: payment_method,
                              amount: refund_amount.abs * -1,
                              response_code: response.authorization,
                              state: 'completed' }, without_protection: true)
        else
          gateway_error(response)
        end
      end
    end

    # Import from future Spree v.2.3.0 d470b31798f37
    def build_source
      return if source_attributes.nil?
      return unless payment_method.andand.payment_source_class

      self.source = payment_method.payment_source_class.new(source_attributes)
      source.payment_method_id = payment_method.id
      source.user_id = order.user_id if order
    end

    private

    def calculate_refund_amount(refund_amount = nil)
      refund_amount ||= credit_allowed >= order.outstanding_balance.abs ? order.outstanding_balance.abs : credit_allowed.abs
      refund_amount.to_f
    end

    def create_payment_profile
      return unless source.is_a?(CreditCard)
      return unless source.try(:save_requested_by_customer?)
      return unless source.number || source.gateway_payment_profile_id
      return unless source.gateway_customer_profile_id.nil?

      payment_method.create_profile(self)
    rescue ActiveMerchant::ConnectionError => e
      gateway_error e
    end

    # Don't charge fees for invalid or failed payments.
    # This is called twice for failed payments, because the persistence of the 'failed'
    # state is acheived through some trickery using an after_rollback callback on the
    # payment model. See Spree::Payment#persist_invalid
    def revoke_adjustment_eligibility
      return unless adjustment.try(:reload)
      return if adjustment.finalized?

      adjustment.update_attribute(:eligible, false)
      adjustment.finalize!
    end
  end
end
