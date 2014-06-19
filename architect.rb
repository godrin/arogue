require_relative './objects.rb'
require_relative './map.rb'

Pos=Struct.new(:x,:y)
class Pos
  def +(p)
    Pos.new(self.x+p.x,self.y+p.y)
  end
  def -(p)
    Pos.new(self.x-p.x,self.y-p.y)
  end

  def len
    Math.sqrt(self.x*self.x + self.y*self.y)
  end
  def neighbors
    [[-1,0],[-1,-1],[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1]].map{|a,b|
      Pos.new(self.x+a,self.y+b)
    }
  end
  def ==(o)
    self.x==o.x and self.y==o.y
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

  def self.fromPos(x1,y1,x2,y2)
    Rect.new([x1,x2].min,[y1,y2].min,(x2-x1).abs,(y2-y1).abs)
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
  def top_left
    Pos.new(@x1,@y1)
  end
  def top_right
    Pos.new(@x2,@y1)
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

  def borderPositions
    ((@x1..@x2).map{|x|
      [Pos.new(x,@y1),Pos.new(x,@y2)]
    }+
    (@y1..@y2).map{|y|
      [Pos.new(@x1,y),Pos.new(@x2,y)]
    }).flatten
  end

  def intersect (other)
    #returns true if this rectangle intersects with another one
    return (@x1 <= other.x2 and @x2 >= other.x1 and
            @y1 <= other.y2 and @y2 >= other.y1)
  end

  def intersects_list(list)
    list.select{|other|
      self.intersect(other)
    }.length >0
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



def make_map2
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
  trials=0
  directfails=0
  begin
    #random width and height
    w = TCOD.random_get_int(nil, ROOM_MIN_SIZE, ROOM_MAX_SIZE)
    h = TCOD.random_get_int(nil, ROOM_MIN_SIZE, ROOM_MAX_SIZE)
    #random position without going out of the boundaries of the map
    x = TCOD.random_get_int(nil, 1, MAP_WIDTH - w - 2)
    y = TCOD.random_get_int(nil, 1, MAP_HEIGHT - h - 2)


    #"Rect" class makes rectangles easier to work with
    new_room = Rect.new(x, y, w, h)

    rects=[new_room]

    #run through the other rooms and see if they intersect with this one
    if new_room.intersects_list(rooms)
      directfails+=1
      failed=true
    end

    if not failed

      new_x, new_y = *new_room.center

      if rooms.length > 0
        #all rooms after the first
        #connect it to the previous room with a tunnel

        #center coordinates of previous room
        prev_x, prev_y = *rooms[-1].center()

        #draw a coin(random number that.equal? either 0 or 1)
        if rand(2) == 1
          #first move horizontally, then vertically
          rects << Rect.fromPos(prev_x, prev_y, new_x, prev_y)
          rects << Rect.fromPos(new_x,  prev_y, new_x, new_y)
        else
          #first move vertically, then horizontally
          rects << Rect.fromPos(prev_x, prev_y, prev_x, new_y)
          rects << Rect.fromPos(prev_x,  new_y, new_x, new_y)
        end
      end

      #this means there are no intersections, so this room.equal? valid
      if rects.select{|r|r.intersects_list(rooms[0..-2])}.length==0

        #"paint" it to the map's tiles
        rects.each{|r|
          make_free(map,r)
        }

        objects<<place_objects( new_room, rooms.length, $architect)
        objects.flatten!

        #finally, append the new room to the list
        rooms.push(new_room)
        #rooms.concat(rects)
      end
    end
    trials+=1
  end while rooms.length < MAX_ROOMS and trials<1000000
  pp "TRIALS",trials, rooms.length,directfails
  Map.new(map, objects, mapRect)
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
  trials=0
  directfails=0
  begin
    #random width and height
    w = rand(ROOM_MAX_SIZE-ROOM_MIN_SIZE)+ROOM_MIN_SIZE
    h = rand(ROOM_MAX_SIZE-ROOM_MIN_SIZE)+ROOM_MIN_SIZE
    #random position without going out of the boundaries of the map
    x = rand(MAP_WIDTH-w-2)+1
    y = rand(MAP_HEIGHT-h-2)+1

    #"Rect" class makes rectangles easier to work with
    new_room = Rect.new(x, y, w, h)

    rects=[new_room]

    #run through the other rooms and see if they intersect with this one
    if new_room.intersects_list(rooms)
      directfails+=1
      failed=true
    end

    if not failed

      new_x, new_y = *new_room.center

      if rooms.length > 0
        #all rooms after the first
        #connect it to the previous room with a tunnel

        #center coordinates of previous room
        prev_x, prev_y = *rooms[-1].center()

        #draw a coin(random number that.equal? either 0 or 1)
        if rand(2) == 1
          #first move horizontally, then vertically
          rects << Rect.fromPos(prev_x, prev_y, new_x, prev_y)
          rects << Rect.fromPos(new_x,  prev_y, new_x, new_y)
        else
          #first move vertically, then horizontally
          rects << Rect.fromPos(prev_x, prev_y, prev_x, new_y)
          rects << Rect.fromPos(prev_x,  new_y, new_x, new_y)
        end
      end

      #this means there are no intersections, so this room.equal? valid
      if rects.select{|r|r.intersects_list(rooms[0..-2])}.length==0

        #"paint" it to the map's tiles
        rects.each{|r|
          make_free(map,r)
        }

        objects<<place_objects( new_room, rooms.length, $architect)
        objects.flatten!

        #finally, append the new room to the list
        rooms.push(new_room)
        #rooms.concat(rects)
      end
    end
    trials+=1
  end while rooms.length < MAX_ROOMS and trials<1000000
  pp "TRIALS",trials, rooms.length,directfails
  Map.new(map, objects, mapRect)
end
