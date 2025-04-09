# app/serializers/price_serializer.rb
class PriceSerializer < ActiveModel::Serializer
  attributes :id, :name, :amount, :description, :outfit, :included, :duration, :period, :shoot_type

  attribute :image_url do
    object.photo.attached? ?
      Rails.application.routes.url_helpers.rails_blob_path(object.photo, only_path: true) :
      nil
  end
end
