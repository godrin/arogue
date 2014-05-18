
Map=Struct.new(:map,:playerPos,:objects)

Pos=Struct.new(:x,:y)

class Rect
  attr_accessor :x1, :y1, :x2, :y2
  #a rectangle on the map. used to characterize a room.
  def initialize (x, y, w, h)
    @x1 = x
    @y1 = y
    @x2 = x + w
    @y2 = y + h
  end
 
  def center
    center_x = (@x1 + @x2) / 2
    center_y = (@y1 + @y2) / 2
    [center_x, center_y]
  end
  def shrink(d)
    Rect.new(x1+d,y1+d,w-2*d,h-2*d)
  end
 
  def intersect (other)
    #returns true if this rectangle intersects with another one
    return (@x1 <= other.x2 and @x2 >= other.x1 and
      @y1 <= other.y2 and @y2 >= other.y1)
  end
  def w
    @x2-@x1
  end
  def h
    @y2-@y1
  end
  def xywh
    [@x1,@y1,w,h]
  end
end

def create_room(map,room)
  #go through the tiles in the rectangle and make them passable
  p "#{room.x1}, #{room.x2}, #{room.y1}, #{room.y2}"
  (room.x1 + 1 ... room.x2).each do |x|
    (room.y1 + 1 ... room.y2).each do |y|
      map[x][y].blocked = false
      map[x][y].block_sight = false
    end
  end
end

def create_h_tunnel(map,x1, x2, y)
  #horizontal tunnel. min() and max() are used in case x1>x2
  ([x1,x2].min ... [x1,x2].max + 1).each do |x|
    map[x][y].blocked = false
    map[x][y].block_sight = false
  end
end

def create_v_tunnel(map,y1, y2, x)
  #vertical tunnel
  ([y1,y2].min ... [y1,y2].max + 1).each do |y|
    map[x][y].blocked = false
    map[x][y].block_sight = false
  end
end

def place_objects(room)
  objects = []
  #choose random number of monsters
  num_monsters = TCOD.random_get_int(nil, 0, MAX_ROOM_MONSTERS)

  num_monsters.times do
    #choose random spot for this monster
    x = TCOD.random_get_int(nil, room.x1, room.x2)
    y = TCOD.random_get_int(nil, room.y1, room.y2)

    if TCOD.random_get_int(nil, 0, 100) < 80  #80% chance of getting an orc
      #create an orc
      monster = Obj.new(x, y, 'o', TCOD::Color::DESATURATED_GREEN)
    else
      #create a troll
      monster = Obj.new(x, y, 'T', TCOD::Color::DARKER_GREEN)
    end


    objects<<monster
  end
  objects
end

def make_map
  # fill map with "blocked" tiles
  #map = [[0]*MAP_HEIGHT]*MAP_WIDTH
  map = []
  objects = []
  playerPos = nil

  0.upto(MAP_WIDTH-1) do |x|
    map.push([])
    0.upto(MAP_HEIGHT-1) do |y|
      map[x].push(Tile.new(true))
    end
  end

  rooms = []
  num_rooms = 0

  0.upto(MAX_ROOMS) do |r|
    #random width and height
    w = TCOD.random_get_int(nil, ROOM_MIN_SIZE, ROOM_MAX_SIZE)
    h = TCOD.random_get_int(nil, ROOM_MIN_SIZE, ROOM_MAX_SIZE)
    #random position without going out of the boundaries of the map
    x = TCOD.random_get_int(nil, 0, MAP_WIDTH - w - 1)
    y = TCOD.random_get_int(nil, 0, MAP_HEIGHT - h - 1)


    #"Rect" class makes rectangles easier to work with
    new_room = Rect.new(x, y, w, h)

    #run through the other rooms and see if they intersect with this one
    failed = false
    rooms.each do |other_room|
      if new_room.intersect(other_room)
        failed = true
        break
      end
    end

    unless failed
      #this means there are no intersections, so this room.equal? valid

      #"paint" it to the map's tiles
      create_room(map,new_room)

      objects<<place_objects( new_room)
      objects.flatten!

      #center coordinates of new room, will be useful later
      new_x, new_y = new_room.center


      #there's a 30% chance of placing a skeleton slightly off to the center of this room
      if TCOD.random_get_int(nil, 1, 100) <= 30
        skeleton = Obj.new(new_x + 1, new_y, SKELETON_TILE, TCOD::Color::LIGHT_YELLOW)
        objects.push(skeleton)
      end

      if num_rooms == 0
        #this.equal? the first room, where the $player starts at
        playerPos = Pos.new(new_x, new_y)
      else
        #all rooms after the first
        #connect it to the previous room with a tunnel

        #center coordinates of previous room
        prev_x, prev_y = rooms[num_rooms-1].center()

        #draw a coin(random number that.equal? either 0 or 1)
        if TCOD.random_get_int(nil, 0, 1) == 1
          #first move horizontally, then vertically
          create_h_tunnel(map, prev_x, new_x, prev_y)
          create_v_tunnel(map, prev_y, new_y, new_x)
        else
          #first move vertically, then horizontally
          create_v_tunnel(map, prev_y, new_y, prev_x)
          create_h_tunnel(map, prev_x, new_x, new_y)
        end
      end

      #finally, append the new room to the list
      rooms.push(new_room)
      num_rooms += 1
    end
  end
  map=Map.new(map, playerPos, objects)
  objects.each{|o|o.map=map}

  map
end

