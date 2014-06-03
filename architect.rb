require_relative './objects.rb'

Map=Struct.new(:map,:objects, :rect)

Pos=Struct.new(:x,:y)
class Pos
  def +(p)
    Pos.new(self.x+p.x,self.y+p.y)
  end
  def -(p)
    Pos.new(self.x-p.x,self.y-p.y)
  end
end

class Rect
  attr_accessor :x1, :y1, :x2, :y2
  #a rectangle on the map. used to characterize a room.
  def initialize (x, y, w, h)
    @x1 = x
    @y1 = y
    @x2 = x + w
    @y2 = y + h
  end

  def topleft
    Pos.new(@x1,@y1)
  end
 
  def center
    center_x = (@x1 + @x2) / 2
    center_y = (@y1 + @y2) / 2
    Pos.new(center_x, center_y)
  end
  def anywhere
    Pos.new(@x1+rand(w-1)+1,@y1+rand(h-1)+1)
  end
  def top_middle
    Pos.new((@x1+@x2)/2,@y1+1)
  end
  def shrink(d)
    Rect.new(x1+d,y1+d,w-2*d,h-2*d)
  end
  def moved(x,y)
    Rect.new(x1+x,y1+y,w,h)
  end
  def contains(pos)
    @x1<=pos.x and @x2>pos.x and @y1<=pos.y and @y2>pos.y
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

  def each
    (@x1..@x2).each{|x|
      (@y1..@y2).each{|y|
        yield Pos.new(x,y)
      }
    }
  end
end

def make_free(map,rect)
  rect.each{|p|
    x,y=*p
    cell=map[x][y]
    cell.blocked = false
    cell.block_sight = false
  }
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

def place_objects(room, num_rooms, object_definition)
  objects = []
  #choose random number of monsters
  num_monsters = TCOD.random_get_int(nil, 0, MAX_ROOM_MONSTERS)

  object_definition.each{|obj_def|
    cond,probability,action=obj_def
    if rand<probability
      case num_rooms
      when cond
        1.upto(100) do
          obj = action.call(room)
          unless objects.find{|o|o.x==obj.x and o.y==obj.y}
            objects << obj
            break
          end
        end
      end
    end
  }

  objects
end

def make_map
  # fill map with "blocked" tiles
  map = []
  objects = []

  mapRect=Rect.new(0,0,MAP_WIDTH,MAP_HEIGHT)

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
    x = TCOD.random_get_int(nil, 1, MAP_WIDTH - w - 2)
    y = TCOD.random_get_int(nil, 1, MAP_HEIGHT - h - 2)


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
      make_free(map,new_room)

      objects<<place_objects( new_room, num_rooms, $architect)
      objects.flatten!

      #center coordinates of new room, will be useful later
      new_x, new_y = *new_room.center


      if num_rooms > 0
        #all rooms after the first
        #connect it to the previous room with a tunnel

        #center coordinates of previous room
        prev_x, prev_y = *rooms[num_rooms-1].center()

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
  Map.new(map, objects, mapRect)
end

