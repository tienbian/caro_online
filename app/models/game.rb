class Game < ActiveRecord::Base
  belongs_to :user_x ,class_name: 'User', foreign_key: 'player_x_id'
  belongs_to :user_y ,class_name: 'User', foreign_key: 'player_o_id'
 
  belongs_to :winner, class_name: 'User', foreign_key: 'winner_id'

end