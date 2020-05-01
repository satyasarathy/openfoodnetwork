FactoryBot.define do
  factory :filter_order_cycles_tag_rule, class: TagRule::FilterOrderCycles do
    enterprise { FactoryBot.create :distributor_enterprise }
  end

  factory :filter_shipping_methods_tag_rule, class: TagRule::FilterShippingMethods do
    enterprise { FactoryBot.create :distributor_enterprise }
  end

  factory :filter_products_tag_rule, class: TagRule::FilterProducts do
    enterprise { FactoryBot.create :distributor_enterprise }
  end

  factory :filter_payment_methods_tag_rule, class: TagRule::FilterPaymentMethods do
    enterprise { FactoryBot.create :distributor_enterprise }
  end

  factory :tag_rule, class: TagRule::DiscountOrder do
    enterprise { FactoryBot.create :distributor_enterprise }
    before(:create) do |tr|
      tr.calculator = Spree::Calculator::FlatPercentItemTotal.new(calculable: tr)
    end
  end
end
