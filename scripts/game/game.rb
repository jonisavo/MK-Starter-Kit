class Game
  # @return [Game::Player] the player object.
  attr_accessor :player
  # @return [Game::Switches] the global game switches.
  attr_accessor :switches
  # @return [Game::Variables] the global game variables.
  attr_accessor :variables
  # @return [Hash<Fixnum, Game::Map>] the global collection of game maps.
  attr_accessor :maps

  # Creates a new Game object.
  def initialize
    @maps = {}
  end

  # @return [Game::Map] the map the player is currently on.
  def map
    return @maps[$game.player.map_id]
  end

  def load_map(id)
    # Dispose all game maps/visual maps (might need to add here later)
    # Haven't implemented Game::Map#dispose yet
    @maps.values.each { |e| e.dispose if e.respond_to?(:dispose) }
    @maps = {}
    c = MKD::MapConnections.fetch(id)
    if c
      idx = c[0]
      maps = MKD::MapConnections.fetch.maps[idx]
      maps.keys.each do |x,y|
        id = maps[[x, y]]
        @maps[id] = Game::Map.new(id, x, y)
      end
      x, y = self.map.connection[1], self.map.connection[2]
      diffx = @player.x - x
      diffy = @player.y - y
      @maps.values.each do |m|
        map = $visuals.maps[m.id]
        map.real_x += diffx * 32
        map.real_y += diffy * 32
      end
    else
      @maps[id] = Game::Map.new(id)
    end
  end

  # Updates the maps and player.
  def update
    @maps.values.each(&:update)
    @player.update
  end
end

# Initializes the game
$game = Game.new
$game.switches = Game::Switches.new
$game.variables = Game::Variables.new
$game.player = Game::Player.new(1)
$game.load_map(1)
$visuals.map_renderer.create_tiles if $visuals.map_renderer.empty?
