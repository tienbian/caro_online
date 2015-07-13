class Move < ActiveRecord::Base
  belongs_to :game
  belongs_to :user
  
  
  # Returns true if this move does not exist for the given game yet
  # === Parameters
  # * game = the game that wants to add this move to itself
  # === Example
  def move_available?(game)
    return Move.find(:all, :conditions => ["game_id = ? and x_axis = ? and y_axis = ?", game, self.x_axis, self.y_axis]).empty?
  end
  
  # ******************************
  # ******************************
  protected
  
  def move_is_ok 
    errors.add("Moves", " is not valid, it has already been taken.") unless move_ok?
  end 
  
  def move_ok?
    items = Move.find(:all, :conditions => ["game_id = ? and x_axis = ? and y_axis = ?", self.game, self.x_axis, self.y_axis])
    
    return true if items.empty? or (items[0] == self) else return false
  end

end
