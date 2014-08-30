DIRECTIONS = { :down => 2, :left => 4, :right => 6, :up => 8 }

class Game_Interpreter

  def collide_event(id1, id2)
    e1 = get_character(id1)
	e2 = get_character(id2)        
	collided = is_facing?(e2, e1)
	return collided
  end
  
  def collided?(event_id)
    $game_map.events.each do |k, v|
      e = $game_map.events[k]
      return true  if event_id != e.id && collide_event(event_id, e.id)				
    end
    
	return false
  end
  
  # is e1 facing e2 and next to him?
  def is_facing?(e1, e2)
	# Don't use x/y, because those are rounded integers. Use the real coordintes.
	# Otherwise, they may be in-animation (moving to be adjacent), but model coordinates update
	# before the animation, so it triggers even though it doesnt look like it's touching.
	distance = (e2.real_x - e1.real_x).abs + (e2.real_y - e1.real_y).abs
	return false if distance > 1
	
	to_return = 
		(e1.x == e2.x && e1.y == e2.y - 1 && e1.direction == DIRECTIONS[:down]) || # e1 is on top of e2
		(e1.x == e2.x + 1 && e1.y == e2.y && e1.direction == DIRECTIONS[:left]) || # e1 is on the right of e2		
		(e1.x == e2.x && e1.y == e2.y + 1 && e1.direction == DIRECTIONS[:up]) || # e1 is under e2
		(e1.x == e2.x - 1 && e1.y == e2.y && e1.direction == DIRECTIONS[:right]) # e1 is on the left of e2
	
	return to_return
  end
end