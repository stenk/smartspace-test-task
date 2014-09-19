class CreateBuildings < ActiveRecord::Migration
  def change
    create_table :buildings do |t|
      t.string :address
      t.decimal :long, precision: 10, scale: 6
      t.decimal :lat, precision: 10, scale: 6

      t.timestamps
    end

    add_index :buildings, :address, unique: true
  end
end
