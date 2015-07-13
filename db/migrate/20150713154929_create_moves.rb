class CreateMoves < ActiveRecord::Migration
  def change
    create_table :moves do |t|
      t.string :title
      t.integer :game_id
      t.integer :user_id
      t.integer :x_axis
      t.integer :y_axis

      t.timestamps null: false
    end
  end
end
