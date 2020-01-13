module Encounter
  def self.test_table(table)
    # Allows 3 digits precision (e.g. 0.001)
    factor = 1000.0
    battle = rand(factor) < table.density * factor
    if battle # Generate wild battle
      total = table.list.map { |e| e[0] }.sum
      list = table.list.sort { |a, b| a[0] <=> b[0] }
      num = rand(total)
      enc = nil
      for i in 0...list.size
        if num < list[i][0] # Pick this encounter
          enc = list[i][1]
          break
        else
          num -= list[i][0]
        end
      end
      # Can be nil if the num was higher than the total
      # Not possible, but can be done during testing.
      if !enc.nil?
        poke = Pokemon.new(enc)
        log(:OVERWORLD, "Start battle (#{poke.species.intname}, level #{poke.level})")
      end
    end
  end
end
