require_relative './base.rb'

require_relative './objects.rb'
require_relative './map.rb'


def make_free(map,rect)
  rect.each{|p|
    x,y=*p
    cell=map[x][y]
    unless cell
      puts "NOT FOUND #{x},#{y}"
    end
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


def make_random_room(extends, mapRect)
    w = (extends[:min]..extends[:max]).rand
    h = (extends[:min]..extends[:max]).rand
    #random position without going out of the boundaries of the map
    x = (1..mapRect.w-w-2).rand
    y = (1..mapRect.h-h-2).rand

    #"Rect" class makes rectangles easier to work with
    Rect.new(x, y, w, h)
end

# dx, dy is direction of tunnel
Door=Struct.new(:x,:y,:dx,:dy)

def make_door(room)
  dir=rand<0.5?-1:1
  if rand<0.5
    Door.new((room.x1+1..room.x2-1).rand,dir<0? room.y1 : room.y2,0,dir)
  else
    Door.new(dir<0? room.x1 : room.x2,(room.y1+1..room.y2-1).rand,dir,0)
  end
end

def extend_room(extends,tunnelEndPos,dx,dy)
    w = (extends[:min]..extends[:max]).rand
    h = (extends[:min]..extends[:max]).rand

    if dx!=0
      x=tunnelEndPos.x-(dx<0?w*dx :0)
      y=tunnelEndPos.y-rand(h-1)+1
    else
      x=tunnelEndPos.x-rand(w-1)+1
      y=tunnelEndPos.y-(dy<0?h*dy :0)
    end

    #"Rect" class makes rectangles easier to work with
    Rect.new(x, y, w, h)
end

def make_map(ops={})

  ops||={}
  roomExtends=ops[:roomExtends] || {
    :min=>2,
    :max=>6
  }
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

  firstRoom= make_random_room(roomExtends, mapRect)

  rooms = [firstRoom]

  roomIndex=0
  begin
    curRoom=rooms[roomIndex]
    doors=[]
    doorTries=0
    begin
      #pp "curToom",curRoom
      door= make_door(curRoom)
      doorTries+=1
      pp "DOOR",door
      tunnelLength=rand(5)+2
      pp "tunnel",tunnelLength
      tunnelEndPos=Pos.new(door.x+door.dx*tunnelLength,door.y+door.dy*tunnelLength)
      pp "endpos",tunnelEndPos

      tunnel=Rect.new(door.x+door.dx,
                      door.y+door.dy, 
                      door.dx*(tunnelLength-2), 
                      door.dy*(tunnelLength-2))

      nuRoom =  extend_room(roomExtends,tunnelEndPos,door.dx,door.dy)


      nuRooms=[tunnel,nuRoom]
      pp rooms,nuRooms
      #exit
      hit=false
      ok=true
      nuRooms.each{|r|
        rooms.each{|r2|
          hit|=r.intersect(r2)
        }
          ok&=mapRect.containsRect(r)
      }
      pp hit
      unless hit
        rooms=rooms+nuRooms
      end

    end while doorTries<20 and doors.length<5

  end while rooms.length<5


  pp "ROOMS",rooms

  rooms.each_with_index{|room,index|
    objects<<place_objects( room, index, $architect)
    objects.flatten!
    make_free(map,room)
  }
  return Map.new(map, objects, mapRect)
  exit 1


  trials=0
  directfails=0
  begin
    #"Rect" class makes rectangles easier to work with
    new_room = make_random_room(roomExtends, mapRect)

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
      end
    end
    trials+=1
  end while rooms.length < MAX_ROOMS and trials<1000000
  pp "TRIALS",trials, rooms.length,directfails
  Map.new(map, objects, mapRect)
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
