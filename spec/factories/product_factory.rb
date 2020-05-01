FactoryBot.define do
  factory :product_with_image, parent: :product do
    after(:create) do |product|
      image = File.open(Rails.root.join('app', 'assets', 'images', 'logo-white.png'))
      Spree::Image.create(attachment: image,
                          viewable_id: product.master.id,
                          viewable_type: 'Spree::Variant')
    end
  end

  factory :simple_product, parent: :base_product do
    transient do
      on_demand { false }
      on_hand { 5 }
    end
    after(:create) do |product, evaluator|
      product.master.on_demand = evaluator.on_demand
      product.master.on_hand = evaluator.on_hand
      product.variants.first.on_demand = evaluator.on_demand
      product.variants.first.on_hand = evaluator.on_hand
    end
  end

  factory :taxed_product, parent: :product do
    transient do
      tax_rate_amount 0
      tax_rate_name ""
      zone nil
    end

    tax_category { create(:tax_category) }

    after(:create) do |product, proxy|
      raise "taxed_product factory requires a zone" unless proxy.zone

      create(:tax_rate, amount: proxy.tax_rate_amount,
                        tax_category: product.tax_category,
                        included_in_price: true,
                        calculator: Spree::Calculator::DefaultTax.new,
                        zone: proxy.zone,
                        name: proxy.tax_rate_name)
    end
  end
end

FactoryBot.modify do
  factory :product do
    transient do
      on_hand { 5 }
    end

    primary_taxon { Spree::Taxon.first || FactoryBot.create(:taxon) }

    after(:create) do |product, evaluator|
      product.master.on_hand = evaluator.on_hand
      product.variants.first.on_hand = evaluator.on_hand
    end
  end

  factory :base_product do
    supplier { Enterprise.is_primary_producer.first || FactoryBot.create(:supplier_enterprise) }
    primary_taxon { Spree::Taxon.first || FactoryBot.create(:taxon) }

    unit_value 1
    unit_description ''

    variant_unit 'weight'
    variant_unit_scale 1
    variant_unit_name ''
  end
end
