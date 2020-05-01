class Api::VariantSerializer < ActiveModel::Serializer
  attributes :id, :is_master, :product_name, :sku,
             :options_text, :unit_value, :unit_description, :unit_to_display,
             :display_as, :display_name, :name_to_display,
             :price, :on_demand, :on_hand, :fees, :price_with_fees,
             :tag_list

  delegate :price, to: :object

  def fees
    options[:enterprise_fee_calculator].andand.indexed_fees_by_type_for(object) ||
      object.fees_by_type_for(options[:current_distributor], options[:current_order_cycle])
  end

  def price_with_fees
    if options[:enterprise_fee_calculator]
      object.price + options[:enterprise_fee_calculator].indexed_fees_for(object)
    else
      object.price_with_fees(options[:current_distributor], options[:current_order_cycle])
    end
  end

  def product_name
    object.product.name
  end

  # Used for showing/hiding variants in shopfront based on tag rules
  def tag_list
    return [] unless object.respond_to?(:tag_list)

    object.tag_list
  end
end
