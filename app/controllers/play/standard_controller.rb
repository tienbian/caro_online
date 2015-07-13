class Play::StandardController < ApplicationController

  # Starts a new game when the page is loaded
  # game information is stored in the @game member  
  def index
    start_new_game
  end
  
  # The ajax callable action that is executed when the player drags
  # an X onto the tic tac toe board
  def receive_move_by_player
    @game = Game.find_by_id(params[:game_id])
    do_move_by_player params[:drop_zone]
        
    handle_response_display true
  end

  # The ajax callable action that is executed when the application drags
  # an O onto the tic tac toe board 
  # Note that this action is called automatically right after the call to receive_move_by_player
  # receive_move_by_player sends back a javascript command to call the 
  # javascript method doOnApplicationMove with a 2 second timeout 
  # see markup - /views/play/standard/index.rhtml
  def receive_move_by_application
    @game = Game.find_by_id(params[:game_id])
    do_move_by_application    
    
    handle_response_display false 
  end
  
  # parses the x and y coordinates from the drop zone elements name
  # calls do_move with the coordinates and player x
  def do_move_by_player(drop_zone)
    # parse the x and y coordinates out of the string
    # format is drop_{y}_{x} drop_0_1
    coordinates = drop_zone.split('_')
    y = coordinates[1];
    x = coordinates[2];
    
    do_move @game.player_x, x, y
  end

  # creates the x and y coordinates by calling create_move on the game object
  # calls do_move with the coordinates and player o 
  def do_move_by_application
    # create the applications move
    move = @game.create_move
    unless move.nil? then 
      do_move @game.player_o, move.x_axis, move.y_axis
    else
      raise ' -- ***** do_move_by_application created a nil move *****'
    end
  end
  
  # wrapper method around the game object do_move method
  # if no validation errors exist after the do_move call
  # then the game object is persisted
  def do_move(player, x_axis, y_axis)
    @game.do_move player, x_axis, y_axis

    #if @game.valid? then 
    if @game.errors.empty? then
      @game.save 
    end   
  end
  
  # method that is responsible for rendering the correct rjs files
  # that will send back the correct javascript commands to the browser
  # if any validation errors occured then this method should never get called
  # those would have been handled by render_show_server_error method
  def handle_response_display(last_action_by_player)
    if @game.play_status == StatusType::STANDARD_PLAY
      if last_action_by_player
        render :action => :show_play_complete_player
      else
        render :action => :show_play_complete_application
      end
    elsif @game.play_status == StatusType::PLAYER_WON
      render :action => :show_game_over_player_won
    elsif @game.play_status == StatusType::APPLICATION_WON
      render :action => :show_game_over_application_won
    elsif @game.play_status == StatusType::EQUALIZED
      render :action => :show_game_over_equalized
    else
      # should never occur
      logger.info ' -- handle_response_display general error '
      render_show_server_error
    end
  end
  
  # makes a call to render the show_server_error rjs
  def render_show_server_error
    render :action => :show_server_error
  end

  # **************************************************  
  # **************************************************
  # these methods are just hooks to the rjs files/actions
  def show_play_complete_player
    # nothing
  end

  def show_play_complete_application
    # nothing
  end
  
  def show_game_over_equalized
    # nothing
  end
  
  def show_game_over_player_won
    # nothing
  end
  
  def show_game_over_application_won
    # nothing
  end   
  
  def show_server_error
    # nothing
  end
  # **************************************************  
  # **************************************************  
  
  # Calls start_game on the game object after creating the X and O players
  def start_new_game
    x = create_player_x
    o = create_player_o
    
    @game = Game.start_game(x, o)
  end 
  
  # creates the Player X from the current logged on user 
  def create_player_x   
    return current_user
  end
  
  # creates a new Player O (application player) for each game
  def create_player_o
    p = Player.new()
    p.title = "application"
    p.session_string = "application"
    
    return p    
  end
end