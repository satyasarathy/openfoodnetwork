# Objects of this class represent a line from a spreadsheet that will be processed and used
# to create either product, variant, or inventory records. These objects are referred to as
# "entry" or "entries" throughout product import.

module ProductImport
  class SpreadsheetEntry
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    attr_accessor :line_number, :valid, :validates_as, :product_object,
                  :product_validations, :on_hand_nil, :has_overrides, :units,
                  :unscaled_units, :unit_type, :tax_category, :shipping_category

    attr_accessor :id, :product_id, :producer, :producer_id, :distributor,
                  :distributor_id, :name, :display_name, :sku, :unit_value,
                  :unit_description, :variant_unit, :variant_unit_scale,
                  :variant_unit_name, :display_as, :category, :primary_taxon_id,
                  :price, :on_hand, :on_demand,
                  :tax_category_id, :shipping_category_id, :description,
                  :import_date, :enterprise, :enterprise_id

    def initialize(attrs)
      @validates_as = ''
      remove_empty_skus attrs
      assign_units attrs
    end

    def persisted?
      false # ActiveModel
    end

    def validates_as?(type)
      @validates_as == type
    end

    def errors?
      errors.count > 0 || @product_validations
    end

    def attributes
      attrs = {}
      instance_variables.each do |var|
        attrs[var.to_s.delete("@")] = instance_variable_get(var)
      end
      attrs.except(*non_product_attributes)
    end

    def displayable_attributes
      # Modified attributes list for displaying in user feedback
      attrs = {}
      instance_variables.each do |var|
        attrs[var.to_s.delete("@")] = instance_variable_get(var)
      end
      attrs.except(*non_product_attributes, *non_display_attributes)
    end

    def invalid_attributes
      invalid_attrs = {}
      errors = @product_validations ? self.errors.messages.merge(@product_validations.messages) : self.errors.messages
      errors.each do |attr, message|
        invalid_attrs[attr.to_s] = "#{attr.to_s.capitalize} #{message.first}"
      end
      invalid_attrs.except(*non_product_attributes, *non_display_attributes)
    end

    private

    def remove_empty_skus(attrs)
      attrs.delete('sku') if attrs.key?('sku') && attrs['sku'].blank?
    end

    def assign_units(attrs)
      units = UnitConverter.new(attrs)

      units.converted_attributes.each do |attr, value|
        if respond_to?("#{attr}=")
          public_send("#{attr}=", value) unless non_product_attributes.include?(attr)
        end
      end
    end

    def non_display_attributes
      ['id', 'product_id', 'unscaled_units', 'variant_id', 'enterprise',
       'enterprise_id', 'producer_id', 'distributor_id', 'primary_taxon',
       'primary_taxon_id', 'category_id', 'shipping_category_id',
       'tax_category_id', 'variant_unit_scale', 'variant_unit', 'unit_value']
    end

    def non_product_attributes
      ['line_number', 'valid', 'errors', 'product_object',
       'product_validations', 'inventory_validations', 'validates_as',
       'save_type', 'on_hand_nil', 'has_overrides']
    end
  end
end
