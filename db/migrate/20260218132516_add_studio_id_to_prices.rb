# class AddStudioIdToPrices < ActiveRecord::Migration[7.1]
#   def change
#   end
# end
#
class AddStudioIdToPrices < ActiveRecord::Migration[7.1]
  def change
    add_reference :prices, :studio, null: true, foreign_key: true

    # Add an index for faster lookups when filtering by studio
    # The foreign_key already adds an index, but we also want a composite index
    add_index :prices, [:studio_id, :shoot_type, :still_valid], name: 'index_prices_on_studio_shoot_type_valid'
  end
end
