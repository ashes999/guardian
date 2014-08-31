######
# Variables for your tweakage.
######

DUNGEON_MAP_ID = 1			# Map with generated dungeon
EVENT_MAP_ID = 2			# Map with our events

STAIRS_DOWN_ID = 1			# ID of stairs-down event on EVENT_MAP_ID
STAIRS_UP_ID = 2			# ID of stairs-up event

NUMBER_OF_TILESETS = 10		# Tilesets set up (columns of 3-4 tiles)
CHANGE_EVERY_N_FLOORS = 5	# Change tilesets every this-many floors

# Event IDs of monster events we copy							
WANDERER = 3
PATROLLER = 4
BIG_MONSTER = 6 # direction fix, stalk slowly
MONSTER_TEMPLATE_EVENT_IDS = [WANDERER, PATROLLER] # Default events, randomly picked

TREASURE_CHESTS = {
	:item => 5,
	:equipment => 7
}
# Probability of a chest being a normal, non-equipment chest
ITEM_PROBABILITY = 75

# Used to curb difficulty and drop off easy monsters
# No more than this number of monster types appear on one floor
UNIQUE_MONSTERS_PER_FLOOR = 5

# Used to dynamically generate monsters
class Monster

	attr_reader :earliest_floor, :graphic_file, :graphic_index, :troop_index, :move_speed, :move_frequency, :event_id
	
	# earliest_floor is the minimum floor number before this appears
	# graphic_file is the filename used for the graphic, eg. Monster2
	# graphic_index is the base 0 index (0-7; first row, then second row)
	# troop_index is which troop to use for the battle (base 1)
	# direction is used for big monsters so they appear in the right direction (direction-fixed event).	
	def initialize(earliest_floor, graphic_file, graphic_index, troop_index, move_speed = nil, move_frequency = nil, event_id = nil)
		@earliest_floor = earliest_floor
		@graphic_file = graphic_file
		@graphic_index = graphic_index
		@troop_index = troop_index		
		@event_id = event_id
	end
	
	# Move speed/frequency; these override the actual (copied) source 
	# event move speed/frequency if they are set to non-nil values.
	def move_at(move_speed, move_frequency = nil)
		@move_speed = move_speed
		@move_frequency = move_frequency
		return self
	end
end

class Map
	attr_reader :map_id, :player_pos
	def initialize(map_id, player_pos)
		@map_id = map_id
		@player_pos = player_pos		
	end
end

# These setup monsters, linking troops to event images.
# These are the default monsters -- RTP graphics and troops.
# Note: each monster of a type will always have the same event type
MONSTERS = {
	:slime => Monster.new(1, 'Monster2', 2, 1, WANDERER).move_at(3),
	:bat => Monster.new(1, 'Monster3', 0, 2, PATROLLER).move_at(4),
	:hornet => Monster.new(2, 'Monster3', 2, 3).move_at(4),
	:spider => Monster.new(3, 'Monster3', 7, 4).move_at(4),
	:rat => Monster.new(5, 'Monster3', 4, 5).move_at(4),
	:wisp => Monster.new(7, '!Flame', 5, 6).move_at(3),
	:snake => Monster.new(9, 'Snake', 0, 7).move_at(3),
	:scorpion => Monster.new(11, 'Monster3', 6, 8).move_at(3),
	:jellyfish => Monster.new(13, 'Monster3', 3, 9).move_at(2),
	:man_eating_plant => Monster.new(15, 'Monster2', 0, 10).move_at(2),
	:ghost => Monster.new(17, 'Monster1', 0, 11).move_at(4),
	:skeleton => Monster.new(19, 'Monster1', 1, 12).move_at(4),
	:orc => Monster.new(21, 'Monster1', 2, 13, PATROLLER).move_at(3),
	:imp => Monster.new(23, 'Monster1', 3, 14).move_at(4),
	:gazer => Monster.new(25, 'Monster3', 1, 15).move_at(2),
	:puppet => Monster.new(27, 'Other1', 1, 16).move_at(2),
	:zombie => Monster.new(29, 'TombZombies', 1, 17, WANDERER).move_at(2),
	:cockatrice => Monster.new(31, 'Cockatrice', 0, 18).move_at(3),
	:chimera => Monster.new(30, '$BigMonster1', 0, 19, BIG_MONSTER),
	:mimic => Monster.new(33, 'Mimic', 0, 20, PATROLLER).move_at(3),
	:werewolf => Monster.new(35, 'Other3', 5, 21).move_at(4),
	:sahagin => Monster.new(37, 'Monster3', 5, 22).move_at(3),
	:ogre => Monster.new(35, '$BigMonster2', 3, 23, BIG_MONSTER),	
	:gargoyle => Monster.new(44, 'Gargoyles', 4, 24).move_at(3),
	:lamia => Monster.new(40, '$BigMonster1', 3, 25, BIG_MONSTER),
	:vampire => Monster.new(43, 'Other3', 5, 26).move_at(4),
	:succubus => Monster.new(44, 'Monster2', 3, 27).move_at(4),
	:demon => Monster.new(45, '$BigMonster2', 0, 28, BIG_MONSTER),
	:demon_king => Monster.new(48, 'Monster1', 7, 29).move_at(3),
	:demon_crab => Monster.new(49, '$BigMonster2', 2, 30, BIG_MONSTER)
}

# Floor number => Map instance
CUSTOM_FLOORS = {
	50 => Map.new(4, { :x => 8, :y => 10})
}

#####
# End variables. Change what's below only if you know what you're doing!
#####

# Z values
GROUND = 0
LEVEL = 1
ABOVE = 2

# RPG Maker VX Ace constants
BATTLE_COMMAND_CODE = 301
BATTLE_COMMAND_TROOP_PARAMETER = 1
MOVE_COMMAND_CODE = 205
MOVE_LIST_PARAMETER = 1

class DungeonGenerator	
	
	DataManager.setup({ :dungeon => DungeonGenerator.new })
	attr_reader :floor_num

	def self.instance		
		instance = DataManager.get(:dungeon)				
		return instance		
	end
	
	def initialize
		@floor_num = 0
	end	
	
	def create(source_map_file, went_down = true)	
		if @floor_num.nil?
			@floor_num = 0 
		end
		@floor_num += (went_down ? 1 : -1)
		
		# Global variable is used for custom maps only
		$went_down = went_down
		
		@player_spawn = nil
		
		if !CUSTOM_FLOORS.keys.include?(@floor_num)
			generate(source_map_file, went_down)			
		else
			show_map(CUSTOM_FLOORS[@floor_num], went_down)
		end		
		
		$game_map.display_name = "#{@floor_num}F"			
	end
	
	# Moves players on top of the appropriate stairs (up or down)
	def relocate_player
		if @player_spawn.nil?
			@player_spawn = random_empty_spot
		end
		# Keep the spot close to the near stairs
		$game_player.moveto(@player_spawn[:x], @player_spawn[:y])		
	end
	
	def random_item
		# 90% chance for the first 8 (normal) items
		# 10% chance for the next 8 (stats up) items
		probability = rand(100)
		index = rand($data_items.count / 2)
		index += $data_items.count / 2 if probability >= 90
		index = 1 if index == 0 # base 1, not base 0
		item = $data_items[index]
		return item
	end
	
	def random_equipment_for_this_floor
		# Returns the first 10 items for the first five floors
		# Then shifts to add one newer item and drop the oldest
		collection = rand(2) == 0 ? $data_weapons : $data_armors
		start_index = [1, @floor_num - 10].max # base 1, not base 0
		start_index = [start_index, collection.count - 10].min # Don't overflow
		stop_index = [start_index + 10, collection.count].min
		index = rand(stop_index - start_index) + start_index		
		return collection[index]
	end
	
	def is_custom_map?
		return CUSTOM_FLOORS.keys.include?(@floor_num)
	end
	
	def reset
		@floor_num = 0
	end
	
	# Param: did the user just go up a flight of stairs? 
	# If so, generate the stairs-down next to him, and stairs-up away from him.
	# If not, generate the stairs-up next to him, and stairs-down away from him.
	def generate_stairs(went_down, down_location = nil, up_location = nil)
		near_stairs = went_down == true ? STAIRS_UP_ID : STAIRS_DOWN_ID		
		far_stairs = went_down == true ? STAIRS_DOWN_ID : STAIRS_UP_ID		
		$game_map.setup_events # clears old events		
		
		$game_player.moveto(0, 0) # Fix glitch on custom floors where event can't spawn because player is already here
		
		far_spot = went_down ? down_location : up_location
		far_spot ||= random_empty_spot
		clone_event(far_spot[:x], far_spot[:y], far_stairs, EVENT_MAP_ID)
		
		near_spot = went_down ? up_location : down_location
		near_spot ||= random_empty_spot		
		clone_event(near_spot[:x], near_spot[:y], near_stairs, EVENT_MAP_ID)		
		
		@stairs_down = went_down ? far_stairs : near_stairs
		@stairs_up = went_down ? near_stairs : far_stairs
		@player_spawn = near_spot
		
		$game_player.moveto(@player_spawn[:x], @player_spawn[:y])	
	end
	
	private
	
	def clone_event(x, y, event_id, source_map_id)
		# Clone the event
		$game_map.spawn_event(x, y, event_id, source_map_id)
		
		# Verify that it appeared
		found = false
		$game_map.events.each do |k, v|
			e = $game_map.events[k]
			found = e if e.x == x && e.y == y
		end
		
		raise "Couldn't copy event id=#{event_id} from map id=#{source_map_id} to (#{x}, #{y})" if found == false
	end
	
	def generate(source_map_file, went_down)		
		change_map_synchronously(DUNGEON_MAP_ID, 0, 0) if $game_map.map_id != DUNGEON_MAP_ID
		
		source_map = load_data(sprintf("Data/%s", source_map_file))
		# Change floors every N (eg. five). Wrap around if we didn't setup enough and went over.
		tileset_number = (@floor_num  / CHANGE_EVERY_N_FLOORS) % NUMBER_OF_TILESETS
		
		@tiles = {
			:solid => source_map.data[tileset_number, 0, 0],
			:wall => source_map.data[tileset_number, 1, 0],
			:floor => source_map.data[tileset_number, 2, 0],
			:path => source_map.data[tileset_number, 3, 0]
		}
		
		@tiles[:path] = @tiles[:floor] if @tiles[:path] == 0
		
		@floor_id = tile_type(@tiles[:floor])
		fill_with_solid
		generate_rooms
		connect_rooms		
		
		begin
			$game_map.update_all_autotiles
		rescue NoMethodError => e
			raise 'You need to include KilloZapit\'s AutoTile Update Script. Please download it from here: http://www.rpgmakervxace.net/blog/121/entry-454-autotile-update-script/'
		end
		
		generate_stairs(went_down)
		relocate_player
		generate_monsters		
		add_treasure	
	end
	
	def show_map(map_def, went_down)
		map_id = map_def.map_id
		player_pos = map_def.player_pos
		
		# Transfer player
		change_map_synchronously(map_id, player_pos[:x], player_pos[:y])
		
		# Can't generate events any more since the map changed.		
		# Un-tint screen		
		$game_map.screen.start_tone_change(Tone.new(0, 0, 0, 0), 30)
	end
	
	# reserve_transfer is asynchronous. Wait for it.
	# Use no transition. This code is almost copied
	# from Game_Interpreter.command_201 (Transfer Player)
	def change_map_synchronously(map_id, x, y)		
		$game_temp.fade_type = 0 # black fadeout/in
		$game_player.reserve_transfer(map_id, x, y)		
		Fiber.yield while $game_player.transfer?
	end
	
	# From Game_Interpreter
	def wait(duration)
		duration.times { Fiber.yield }
	end
	
	def add_treasure
		num_treasure_chests = 3 + rand(3) # 3-5
		# Pick which rooms to dump them into
		target_rooms = []
		while target_rooms.count < num_treasure_chests
			r = @rooms.sample
			target_rooms << r unless target_rooms.include?(r)
		end		
		
		target_rooms.each do |r|
			probability = rand(100)
			chest_type = probability <= ITEM_PROBABILITY ? TREASURE_CHESTS[:item] : chest_type = TREASURE_CHESTS[:equipment]			
			# Don't touch borders
			target_x = r.x + rand(r.width - 2) + 1
			target_y = r.y + rand(r.height - 3) + 2 # don't touch top wall
			$game_map.spawn_event(target_x, target_y, chest_type, EVENT_MAP_ID)
			event = $game_map.events[$game_map.events.keys[-1]]			
			
			# Treasure chest's "open" state persists from floor to floor.
			# To get over this, reset the self-switch A.
			set_self_switch($game_map.map_id, event.id, 'A', false)
		end
	end
	
	def set_self_switch(map_id, event_id, self_switch, on)
		switch = [map_id, event_id, self_switch]
		$game_self_switches[switch] = on
	end
	
	def generate_monsters
		# Pick 5-10 from the enemy events
		num_enemies = rand(5) + 5
		while (num_enemies > 0)
			create_monster
			num_enemies -= 1
		end
	end
	
	# dynamically updates the battle troop to match our target
	def create_monster
		events = $game_map.events		
		possible_monsters = MONSTERS.select { |m| MONSTERS[m].earliest_floor <= @floor_num }
		# Limit to only the last UNIQUE_MONSTERS_PER_FLOOR, so we don't get weak monsters in later dungeons		
		if possible_monsters.length > UNIQUE_MONSTERS_PER_FLOOR
			# Convert to array
			possible_monsters = possible_monsters.to_a
			# Trim excess
			possible_monsters = possible_monsters[-UNIQUE_MONSTERS_PER_FLOOR .. -1]
			# Convert back to hash
			temp = {}
			possible_monsters.each do |a|
				temp[a[0]] = a[1]
			end			
			possible_monsters = temp
		end
		
		monster = possible_monsters[possible_monsters.keys.sample]
				
		# Clone the event into a random spot
		location = random_empty_spot			
		event_id = monster.event_id || MONSTER_TEMPLATE_EVENT_IDS.sample
		$game_map.spawn_event(location[:x], location[:y], event_id, EVENT_MAP_ID)					
		event = events[events.keys[-1]]
		
		# Big monsters are strange. You need to set the graphic_index to 0,
		# and set the direction to 2, 4, 6, or 8.
		if monster.graphic_file.downcase.include?('bigmonster')
			event.set_graphic(monster.graphic_file, 0)
			event.direction = 2 * (monster.graphic_index + 1)			
		else
			event.set_graphic(monster.graphic_file, monster.graphic_index)
		end
		
		event.move_speed = monster.move_speed unless monster.move_speed.nil?
		event.move_frequency = monster.move_frequency unless monster.move_frequency.nil?
		
		# event.list.to_s snippet: #<RPG::EventCommand:0x8c20bd4 @indent=0, @code=301, @parameters=[0, 24, true, false]>, ...
		# Find the battle command (code 301), change the troop parameter (index #1)
		battle_command = event.list.find { |e| e.code == BATTLE_COMMAND_CODE } # first event
		battle_command.parameters[BATTLE_COMMAND_TROOP_PARAMETER] = monster.troop_index
	end
	
	def random_empty_spot
		x = rand($game_map.width)
		y = rand($game_map.height)		
		
		while !is_empty?(x, y)			
			x = rand($game_map.width)
			y = rand($game_map.height)
		end		
		
		return {:x => x, :y => y}
	end
	
	# Is it one of our floor tikes? Then it's empty.
	def is_empty?(x, y)
		event_count = $game_map.events_xy(x, y).length	
		# Is it a floor tile? That's all we need.
		return tile_type($game_map.data[x, y, 0]) == @floor_id && event_count == 0
	end
	
	def fill_with_solid
		(0 .. $game_map.width - 1).each do |x|
		  (0 .. $game_map.height - 1).each do |y|			  
			  $game_map.data[x, y, GROUND] = @tiles[:solid]
		  end
		end
	end
	
	def generate_rooms
		@rooms = []
		
		# Maximum room width; the room is at least half this wide.
		# Eg. if you specify 8, you get rooms 4-8 tiles wide.
		max_width = Math.sqrt($game_map.width).to_i * 2
		# Maximum room height; the room is at least half this high.
		# Eg. if you specify 6, you get rooms 3-6 tiles high (including the wall).
		max_height = (max_width * 0.75).to_i
		
		current_x = 1
		current_y = 1
		max_y = 1
				
		while current_y + (max_height / 2) <= $game_map.height - 1 do
			while current_x + (max_width / 2) <= $game_map.width - 1 do
				# As long as we have at least half a width, we can generate a room.
				# But if we don't have a full-width of space, use whatever space is left.
				w = [$game_map.width - current_x - 1, rand(max_width / 2) + max_width / 2].min
				h = [$game_map.height - current_y - 1, rand(max_height / 2) + max_height / 2].min
				
				@rooms << generate_room(current_x, current_y, w, h)
				
				current_x += w + rand(5) + 1 # 5-6 spaces between rooms horizontally
				max_y = [max_y, current_y + h].max
			end
						
			current_x = 1
			current_y = max_y + rand(3) + 1 #1-4 spaces between rooms vertically						
		end
	end
	
	def generate_room(x, y, width, height)
		(x .. x + width - 1).each do |i|			
			(y .. y + height - 1).each do |j|
			
				if j == y
					tile = @tiles[:wall]
				else 
					tile = @tiles[:floor]					
				end
				
				$game_map.data[i, j, GROUND] = tile
			end
		end		
		
		return Room.new(x, y, width, height)
	end
	
	def connect_rooms
		left = @rooms.shuffle
		source = left.delete_at(0)
		
		while (left.length > 0) do
			destination = left.delete_at(0)
			connect_room(source, destination)
			source = destination			
		end
	end
	
	def connect_room(source, target)
		# Pick a random point within the two rooms
		src_x = rand(source.width - 2) + source.x + 1 # Don't start on the edges
		src_y = rand(source.height - 2) + source.y + 2 # Don't start in the wall	
		target_x = rand(target.width - 2) + target.x + 1
		target_y = rand(target.height - 2) + target.y + 2
		
		# Tunnel. Directly. Dunno if we're iterating forward or backward.		
		step_x = target_x > src_x ? 1 : -1
		x = src_x
		while (x != target_x + step_x)
			$game_map.data[x, src_y, GROUND] = @tiles[:path]			
			if $game_map.data[x, src_y - 1, GROUND] == @tiles[:solid]
				$game_map.data[x, src_y - 1, GROUND] = @tiles[:wall]
			end
			x += step_x
		end
		
		step_y = target_y > src_y ? 1 : -1
		y = src_y
		while (y != target_y)
			$game_map.data[target_x, y, GROUND] = @tiles[:path]			
			y += step_y
		end
	end
	
	def tile_type(tile_id)
		type = tile_id
		# 2048/48 is for autotile; otherwise, just give me the normal ID (not -1)
		type = (type - 2048) / 48 if type >= 2048
		return type
	end
	
	class Room
		attr_reader :x, :y, :width, :height
		
		def initialize(x, y, width, height)
			@x = x
			@y = y
			@width = width
			@height = height
		end
		
		def to_s
			return "[#{@x}, #{@y} to #{@x + @width}, #{@y + @height}]"
		end
	end
end

# Used to change the map name dynamically
class Game_Map
	def display_name=(value)
		@map.display_name = value		
	end
end

# Used to set sprites correctly for big monsters
class Game_Event
	def direction=(value)
		@direction = value
	end
	# These two are used to randomize event speed
	def move_speed=(value)
		@move_speed = value
	end
	def move_frequency=(value)
		@move_frequency = value
	end
end

# Disable saving
class Window_MenuCommand
	def add_save_command
	end
end
