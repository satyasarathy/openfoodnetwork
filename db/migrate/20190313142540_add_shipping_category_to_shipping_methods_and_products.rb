class AddShippingCategoryToShippingMethodsAndProducts < ActiveRecord::Migration
  def up
    # This is different from the equivalent Spree migration
    #   Here we are creating the default shipping category even if there are already shipping categories
    default_category = Spree::ShippingCategory.create!(name: "Default")

    Spree::ShippingMethod.all.each do |method|
      method.shipping_categories << default_category if method.shipping_categories.blank?
    end

    Spree::Product.where(shipping_category_id: nil).update_all(shipping_category_id: default_category.id)
  end
end
