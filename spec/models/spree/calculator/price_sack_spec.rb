require 'spec_helper'

describe Spree::Calculator::PriceSack do
  let(:calculator) do
    calculator = Spree::Calculator::PriceSack.new
    calculator.preferred_minimal_amount = 5
    calculator.preferred_normal_amount = 10
    calculator.preferred_discount_amount = 1
    calculator
  end
  let(:line_item) { build(:line_item, price: price, quantity: 2) }

  context 'when the order amount is below preferred minimal' do
    let(:price) { 2 }

    it "uses the preferred normal amount" do
      expect(calculator.compute(line_item)).to eq(10)
    end
  end

  context 'when the order amount is above preferred minimal' do
    let(:price) { 6 }

    it "uses the preferred discount amount" do
      expect(calculator.compute(line_item)).to eq(1)
    end
  end

  context "preferred discount amount is float" do
    before do
      calculator.preferred_normal_amount = 10.4
      calculator.preferred_discount_amount = 1.2
    end

    context 'when the order amount is below preferred minimal' do
      let(:price) { 2 }

      it "uses the float preferred normal amount" do
        expect(calculator.compute(line_item)).to eq(10.4)
      end
    end

    context 'when the order amount is above preferred minimal' do
      let(:price) { 6 }

      it "uses the float preferred discount amount" do
        expect(calculator.compute(line_item)).to eq(1.2)
      end
    end
  end

  context "extends LocalizedNumber" do
    it_behaves_like "a model using the LocalizedNumber module", [:preferred_minimal_amount, :preferred_normal_amount, :preferred_discount_amount]
  end
end
