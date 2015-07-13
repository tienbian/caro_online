class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :title
      t.integer :player_x_id
      t.integer :player_o_id
      t.integer :winner_id
      t.boolean :is_tie_game

      t.timestamps null: false
    end
  end
end
