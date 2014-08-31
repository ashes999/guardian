# Source: http://www.rpgmakervxace.net/blog/121/entry-454-autotile-update-script/

class Game_Map
  
  def update_all_autotiles
    for i in 0...width
      for j in 0...height
        update_autotile(i, j, 0)
        update_autotile(i, j, 1)
      end
    end
  end
  
  def autotile_edge(autotile, x, y, z)
    valid?(x, y) && autotile != autotile_type(x, y, z)
  end
  
  def autotile_wall_edge(autotile, x, y, z)
    if (autotile / 8) % 2 == 1
      return false if autotile_type(x, y, z) + 8 == autotile
    end
    autotile_edge(autotile, x, y, z)
  end
  
  def update_autotile(x, y, z) 
    autotile = autotile_type(x, y, z)
    return if autotile < 0
    index = 0
    case get_autotile_group(autotile)
    when 2
      l = autotile_edge(autotile, x - 1, y, z)
      r = autotile_edge(autotile, x + 1, y, z)
      index = waterfall_autotile_index(l,r)
    when 1
      l = autotile_wall_edge(autotile, x - 1, y, z)
      r = autotile_wall_edge(autotile, x + 1, y, z)
      u = autotile_edge(autotile, x, y - 1, z)
      d = autotile_edge(autotile, x, y + 1, z)
      index = wall_autotile_index(u,d,l,r)
    when 0
      l = autotile_edge(autotile, x - 1, y, z)
      r = autotile_edge(autotile, x + 1, y, z)
      u = autotile_edge(autotile, x, y - 1, z)
      d = autotile_edge(autotile, x, y + 1, z)
      ul = autotile_edge(autotile, x - 1, y - 1, z)
      ur = autotile_edge(autotile, x + 1, y - 1, z)
      dl = autotile_edge(autotile, x - 1, y + 1, z)
      dr = autotile_edge(autotile, x + 1, y + 1, z)
      index = normal_autotile_index(u,d,l,r,ul,ur,dl,dr)
    end
    @map.data[x, y, z] = get_autotile_tile_id(autotile, index)
  end
  
  def get_autotile_tile_id(autotile, index)
    2048 + (48 * autotile) + index
  end
  
  def get_autotile_group(autotile)
    return unless autotile
    return 2 if autotile == 5 or autotile == 7 or 
                autotile == 9 or autotile == 11 or
                autotile == 13 or autotile == 15
    return 1 if autotile >= 48 and autotile <= 79
    return 1 if autotile >= 88 and autotile <= 95
    return 1 if autotile >= 104 and autotile <= 111
    return 1 if autotile >= 120 and autotile <= 127
    return 0
  end
  
  def waterfall_autotile_index(l,r)
    edge = 0
    edge |= 1 if l
    edge |= 2 if r
    return edge
  end
  
  def wall_autotile_index(u,d,l,r)
    edge = 0
    edge |= 1 if l
    edge |= 2 if u
    edge |= 4 if r
    edge |= 8 if d
    return edge
  end
  
  def normal_autotile_index(u,d,l,r,ul,ur,dl,dr)
    edge = 0
    edge |= 1 if l
    edge |= 2 if u
    edge |= 4 if r
    edge |= 8 if d
    corner = 0
    case edge
    when 0
      corner |= 1 if ul
      corner |= 2 if ur
      corner |= 4 if dr
      corner |= 8 if dl
      return corner
    when 1
      corner |= 1 if ur
      corner |= 2 if dr
      return 16 | corner
    when 2
      corner |= 1 if dr
      corner |= 2 if dl
      return 20 | corner
    when 4
      corner |= 1 if dl
      corner |= 2 if ul
      return 24 | corner
    when 8
      corner |= 1 if ul
      corner |= 2 if ur
      return 28 | corner
    when 5
      return 32
    when 10
      return 33
    when 3
      return dr ? 35 : 34
    when 6
      return dl ? 37 : 36
    when 12
      return ul ? 39 : 38
    when 9
      return ur ? 41 : 40
    when 7 
      return 42
    when 11
      return 43
    when 13
      return 44
    when 14
      return 45
    when 15
      return 46
    else
      return 47
    end
  end 
  
end