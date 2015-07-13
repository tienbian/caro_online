class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :x_games, class_name: 'Game', foreign_key: 'player_x_id'
  has_many :o_games, class_name: 'Game' , foreign_key: 'player_o_id'
  
  def get_total_games_played
    self.x_games.to_a.concat(self.o_games.to_a)
  end

  def get_total_games_won
    return Game.find(:all, :conditions => ["winner_id = ?", self]).size
  end

  def get_total_games_equalized
    return Game.find(:all, :conditions => ["player_x_id = ? and is_tie_game = true", self]).size
  end 
  
  def get_total_games_lost
    return get_total_games_played - (get_total_games_won + get_total_games_equalized) - 1
  end
  


end
