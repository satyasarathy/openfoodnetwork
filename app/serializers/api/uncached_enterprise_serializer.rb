module Api
  class UncachedEnterpriseSerializer < ActiveModel::Serializer
    include SerializerHelper

    attributes :orders_close_at, :active

    def orders_close_at
      options[:data].earliest_closing_times[object.id]
    end

    def active
      options[:data].active_distributor_ids.andand.include? object.id
    end
  end
end
