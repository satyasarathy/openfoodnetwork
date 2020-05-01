module OpenFoodNetwork
  class EnterpriseFeeApplicator < Struct.new(:enterprise_fee, :variant, :role)
    def create_line_item_adjustment(line_item)
      create_adjustment(line_item_adjustment_label, line_item.order, line_item)
    end

    def create_order_adjustment(order)
      create_adjustment(order_adjustment_label, order, order)
    end

    private

    def create_adjustment(label, target, calculable)
      adjustment = create_enterprise_fee_adjustment(label, target, calculable)

      AdjustmentMetadata.create! adjustment: adjustment, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: role

      adjustment.set_absolute_included_tax! adjustment_tax(adjustment)
    end

    def create_enterprise_fee_adjustment(label, target, calculable)
      adjustment = enterprise_fee.create_adjustment(label, target, calculable, true)

      # This is necessary when source is a line_item
      #   probably because the association order.adjustments contains "inverse_of :source"
      #   which overrides the value (the line item) set in calculated_adjustment.create_adjustment
      adjustment.source = calculable
      adjustment
    end

    def line_item_adjustment_label
      "#{variant.product.name} - #{base_adjustment_label}"
    end

    def order_adjustment_label
      "#{I18n.t(:enterprise_fee_whole_order)} - #{base_adjustment_label}"
    end

    def base_adjustment_label
      I18n.t(:enterprise_fee_by, type: enterprise_fee.fee_type, role: role, enterprise_name: enterprise_fee.enterprise.name)
    end

    def adjustment_tax(adjustment)
      tax_rates = TaxRateFinder.tax_rates_of(adjustment)

      tax_rates.select(&:included_in_price).sum do |rate|
        rate.compute_tax adjustment.amount
      end
    end
  end
end
