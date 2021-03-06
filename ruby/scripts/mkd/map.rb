module MKD
  class Map < Serializable
    Cache = []

    attr_accessor :id
    attr_accessor :dev_name
    attr_accessor :display_name
    attr_accessor :width
    attr_accessor :height
    attr_accessor :tiles
    attr_accessor :tilesets
    attr_accessor :events
    attr_accessor :encounter_tables

    def initialize(id = 0)
      @id = id
      @dev_name = ""
      @display_name = ""
      @width = 0
      @height = 0
      @tiles = []
      @tilesets = [0]
      @events = {}
      @encounter_tables = []
    end

    # @param [id] the ID of the map to fetch.
    # @return [Map] the map with the specified ID.
    def self.fetch(id)
      return Cache[id] if Cache[id]
      Cache[id] = FileUtils.load_data("data/maps/map#{id.to_digits(3)}.mkd", :map)
      return Cache[id]
    end

    def name
      return @display_name
    end

    #temp
    def save
      FileUtils.save_data("data/maps/map#{@id.to_digits}.mkd", :map, self)
    end
  end
end
