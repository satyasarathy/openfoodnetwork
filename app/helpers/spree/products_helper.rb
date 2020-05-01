# frozen_string_literal: true

module Spree
  module ProductsHelper
    def product_has_variant_unit_option_type?(product)
      product.option_types.any? { |option_type| variant_unit_option_type? option_type }
    end

    def variant_unit_option_type?(option_type)
      Spree::Product.all_variant_unit_option_types.include? option_type
    end
  end
end
