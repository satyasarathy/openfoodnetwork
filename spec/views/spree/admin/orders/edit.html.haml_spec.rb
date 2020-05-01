require "spec_helper"

describe "spree/admin/orders/edit.html.haml" do
  include AuthenticationWorkflow
  helper Spree::BaseHelper # required to make pretty_time work

  around do |example|
    original_config = Spree::Config[:enable_invoices?]
    example.run
    Spree::Config[:enable_invoices?] = original_config
  end

  before do
    controller.singleton_class.class_eval do
      def current_ability
        Spree::Ability.new(Spree.user_class.new)
      end
    end

    allow(view).to receive_messages spree_current_user: create_enterprise_user

    order = create(:completed_order_with_fees)
    order.distributor = create(:distributor_enterprise)
    assign(:order, order)
    assign(:shops, [order.distributor])
    assign(:order_cycles, [])
  end

  describe "order values" do
    it "displays order shipping costs, transaction fee and order total" do
      render

      expect(rendered).to have_content("Shipping: UPS Ground $6.00")
      expect(rendered).to have_content("Transaction fee: $10.00")
      expect(rendered).to have_content("Order Total $36.00")
    end
  end
end
