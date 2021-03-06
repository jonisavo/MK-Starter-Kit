class Game
  # @return [Game::Player] the player object.
  attr_accessor :player
  # @return [Game::Switches] the global game switches.
  attr_accessor :switches
  # @return [Game::Variables] the global game variables.
  attr_accessor :variables
  # @return [Hash<Integer, Game::Map>] the global collection of game maps.
  attr_accessor :maps

  # Creates a new Game object.
  def initialize
    @maps = {}
  end

  # @return [Game::Map] the map the player is currently on.
  def map
    return @maps[$game.player.map_id]
  rescue
    msgbox caller
    abort
  end

  def setup
    Input.update
    $visuals.dispose
    $visuals = nil
    $visuals = Visuals.new
    @maps.each_value { |e| e.setup_visuals }
    @player.setup_visuals
    $visuals.map_renderer.create_tiles
    $visuals.maps.each_value do |e|
      e.real_x -= @player.global_x * 32
      e.real_y -= @player.global_y * 32
    end
    $visuals.map_renderer.move_x(@player.global_x * 32)
    $visuals.map_renderer.move_y(@player.global_y * 32)
    $game.update
    $visuals.update
  end

  def load_map(id)
    # TODO: Dispose all game maps/visual maps (might need to add here later)
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

  def get_map_from_connection(map, mapx, mapy)
    if mapx >= 0 && mapy >= 0 && mapx < map.width && mapy < map.height
      return [map.id, mapx, mapy]
    end
    mx, my = map.connection[1], map.connection[2]
    gx, gy = mx + mapx, my + mapy
    if gx >= 0 && gy >= 0
      maps = MKD::MapConnections.fetch.maps[map.connection[0]]
      maps.keys.each do |x,y|
        mid = maps[[x, y]]
        next if mid == $game.map.id
        map = MKD::Map.fetch(mid)
        width, height = map.width, map.height
        if gx >= x && gy >= y && gx < x + width && gy < y + height
          mapx = gx - x
          mapy = gy - y
          return [mid, mapx, mapy]
        end
      end
    end
    return nil
  end

  # @return [Boolean] whether there are any active events on any map.
  def any_events_running?
    return @maps.values.any? { |m| m.event_running? }
  end

  # Updates the maps and player.
  def update
    @maps.values.each(&:update)
    @player.update
  end

  def self.get_save_data
    data = {
      game: $game,
      trainer: $trainer
    }
  end

  def self.get_save_folder
    base_path = Dir.home
    if OS.windows?
      base_path = ENV['APPDATA'] if File.writable?(ENV['APPDATA'])
    end
    base_path = "." if !File.writable?(base_path)
    return base_path.gsub(/\\\\/, "/") + "/.mkgames/" + GAME_NAME
  end

  def self.save_exists?
    return File.file?(Game.get_save_folder + "/save.mkd")
  end

  def self.save_game
    folder = Game.get_save_folder
    FileUtils.mkdir_p(folder) if !Dir.exists?(folder)
    filename = folder + "/save.mkd"
    if File.file?(filename)
      FileUtils.copy(filename, filename + ".bak")
    end
    begin
      f = File.new(filename, 'wb')
      f.write YAML.dump({type: :savefile, data: Game.get_save_data})
      f.close
      File.delete(filename + ".bak") if File.file?(filename + ".bak")
      return true
    rescue
      FileUtils.move(filename + ".bak", filename) if File.file?(filename + ".bak")
      return false
    end
  end

  def self.load_game # to implement
    if !Game.save_exists?
      raise "No save file could be found."
    else
      filename = Game.get_save_folder + "/save.mkd"
      begin
        f = File.open(filename, 'rb')
        data = YAML.load(f.read)
        f.close
      rescue
        raise "Invalid MKD file - #{filename}\n\nFile cannot be parsed by YAML."
      end
      validate_mkd(data)
      data = data[:data]
      $trainer = data[:trainer]
      $game = data[:game]
      $game.setup
    end
  end
end
