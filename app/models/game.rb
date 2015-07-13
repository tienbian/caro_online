class Game < ActiveRecord::Base
  belongs_to :user_x ,class_name: 'User', foreign_key: 'player_x_id'
  belongs_to :user_y ,class_name: 'User', foreign_key: 'player_o_id'
 
  belongs_to :winner, class_name: 'User', foreign_key: 'winner_id'

  attr_reader :play_status

  # This Class method returns a new Game object with the associated players X and O
  def self.start_game(player_x, player_o)
    g = Game.new(:title => "#{player_x.title} vs. #{player_o.title}")
    g.player_x = player_x
    g.player_o = player_o

    g.save

    return g
  end

  # Returns true if the game has been won or equalized
  def game_over?
    return true if game_won? or game_equalized? else false
  end

  # Returns true if the game has been equalized
  def game_equalized?
    return true if self.moves.size.eql?(9) and not game_won? else false
  end

  # Returns true if the game has been won
  # === Remarks
  # This is a brute force sql approach to determining if the game has been won
  # There is a lot of room for optimization here, both in performance (database calls)
  # and in the coding itself, if we wanted to create a dynamic board say 4x4 or 5x5, this starts to fall short very fast
  # can you say 'smelly code'?
  def game_won?
    return false if self.moves.nil? or (self.moves.size < 5)

    # horizontal wins
    return true if win_found("((x_axis = 0 and y_axis = 0) OR (x_axis = 1 and y_axis = 0) OR (x_axis = 2 and y_axis = 0))")
    return true if win_found("((x_axis = 0 and y_axis = 1) OR (x_axis = 1 and y_axis = 1) OR (x_axis = 2 and y_axis = 1))")
    return true if win_found("((x_axis = 0 and y_axis = 2) OR (x_axis = 1 and y_axis = 2) OR (x_axis = 2 and y_axis = 2))")

    # vertical wins
    return true if win_found("((x_axis = 0 and y_axis = 0) OR (x_axis = 0 and y_axis = 1) OR (x_axis = 0 and y_axis = 2))")
    return true if win_found("((x_axis = 1 and y_axis = 0) OR (x_axis = 1 and y_axis = 1) OR (x_axis = 1 and y_axis = 2))")
    return true if win_found("((x_axis = 2 and y_axis = 0) OR (x_axis = 2 and y_axis = 1) OR (x_axis = 2 and y_axis = 2))")

    # diagonal
    return true if win_found("((x_axis = 0 and y_axis = 0) OR (x_axis = 1 and y_axis = 1) OR (x_axis = 2 and y_axis = 2))")
    return true if win_found("((x_axis = 2 and y_axis = 0) OR (x_axis = 1 and y_axis = 1) OR (x_axis = 0 and y_axis = 2))")

    # else
    return false

  end

  def win_found(criteria)
    current_player = self.moves[-1].player
    moves = Move.where("game_id = ?", self.id)
      .where("player_id = ?", current_player.id)
      .where(criteria)

    (moves.length == 3)
  end

  # This method performs the following checks and returns false if they exist
  # 1. has the game already been won
  # 2. is it the players turn yet
  def does_context_allow_move(player)
    # check 1: is the game already over?
    # why this works and self.winner does not I do not understand
    if not winner.nil? then
      # I thought this would make self.valid? return false?
      self.errors.add('move not allowed, game is already over.', '')
      return false
    end

    # check 2: is players turn?
    if not self.moves.empty? and self.find_last_move.player == player then
      self.errors.add('move cannot be played, it is not your turn.', '')
      return false
    end

    # else
    return true
  end

  # THe do move method creates a new move based on the method parameters
  # but before adding it to the game it verifies that the move is legal
  # If the move was valid then sets the play_status property so the UI knows what to do
  def do_move player, x, y

    if not does_context_allow_move(player) then return end

    move = Move.new(:title => "Move (#{x}, #{y})")
    move.player = player
    move.x_axis = x
    move.y_axis = y

    # check if move alreay played
    if move.move_available?(self) then
      self.moves << move
    else
      self.errors.add('move has already been taken', '')
      return
    end

    set_play_status player
  end

  # Method that sets the play_status member
  def set_play_status(player)
    if not game_over? then
      @play_status = StatusType::STANDARD_PLAY
    elsif game_equalized? then
      self.update_attributes :is_tie_game => true
      @play_status = StatusType::EQUALIZED
    elsif game_won?
      # setting the member and then later save issues NULL?
      # forced to use update_attributes explicitly?
      #self.winner = player
      self.update_attributes :winner => player

      if self.winner == self.player_x then
        @play_status = StatusType::PLAYER_WON
      else
        @play_status = StatusType::APPLICATION_WON
      end
    end

    # logger.info 'Game.set_play_status complete; Play Status = ' + @play_status
  end

  # Method that creates and returns the applications move
  # Uses random numbers to determine what move to try
  # verifies that the move is available before returning
  # if the move is not available then it calls it self recursively until found
  def create_move
    # the board is full game over
    return if self.moves.size >= 9

    if @safe_gaurd_count.nil? then @safe_gaurd_count = 0 end
    @safe_gaurd_count = @safe_gaurd_count + 1

    move = Move.new()
    move.x_axis = rand(3)
    move.y_axis = rand(3)

    if move.move_available?(self) then
      return move
    else
      if @safe_gaurd_count > 50 then raise "Possible endless loop in process. aborting operation!" end
      # call recursive until found
      return create_move
    end
  end



  # *****************************************************
  # *****************************************************
  protected

  # def win_found(criteria)
  #   current_player = @moves[-1].player
  #   return (Move.find(:all, :conditions => [criteria, self, current_player]).size == 3)
  # end

  def board_is_not_full
    errors.add("The game is over no more moves can be made.") unless self.moves.size <= 9
  end

  def find_last_move
    return Move.find(:first, :conditions => ['game_id = ?', self], :order => "id DESC")
  end

end