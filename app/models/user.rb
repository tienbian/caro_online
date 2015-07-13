class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :x_games, class_name: 'Game', foreign_key: 'player_x_id'
  has_many :o_games, class_name: 'Game' , foreign_key: 'player_o_id'
  
  def game_played
    self.x_games.to_a.concat(self.o_games.to_a)
  end

  def wins
    game_played.select{|game| game.winner == self.name}.count
  end


end
