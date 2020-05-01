require "tasks/sample_data/logging"

class TaxonFactory
  include Logging

  def create_samples
    log "Creating taxonomies:"
    taxonomy = Spree::Taxonomy.find_or_create_by_name!('Products')
    taxons = ['Vegetables', 'Fruit', 'Oils', 'Preserves and Sauces', 'Dairy', 'Meat and Fish']
    taxons.each do |taxon_name|
      create_taxon(taxonomy, taxon_name)
    end
  end

  private

  def create_taxon(taxonomy, taxon_name)
    return if Spree::Taxon.where(name: taxon_name).exists?

    log "- #{taxon_name}"
    Spree::Taxon.create!(
      name: taxon_name,
      parent_id: taxonomy.root.id,
      taxonomy_id: taxonomy.id
    )
  end
end
