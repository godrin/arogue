require_relative './path.rb'

MAP_WIDTH = 50 #SCREEN_WIDTH - 20
#
MAP_HEIGHT = 50 #SCREEN_HEIGHT
Map=Struct.new(:map,:objects, :rect)
class Map
  include Path::Finder

  @@obj_fov_map = TCOD.map_new(MAP_WIDTH, MAP_HEIGHT)

  def [](x,y=nil)
    if x.is_a?(Symbol)
      super(x)
    else
      self.map[x][y]
    end
  end
  def player
    @player||=find(:player)
  end

  def find(type)
    select(type)[0]
  end

  def select(type)
    objects.select{|o|o.type==type}
  end
  def blocked(x,y)
    unless self.rect.contains(Pos.new(x,y))
      return [:wall]
    end
    blockedBy=[]
    blockedBy << :wall if self[x,y].blocked
    blockedBy+= self.objects.select{|o|o.x==x and o.y==y and o.block }
    if blockedBy.empty? 
      nil 
    else
      blockedBy
    end
  end
  def objects(x=nil,y=nil)
    if x.nil? and y.nil?
      self[:objects]
    else
      self[:objects].select{|o|o.x==x and o.y==y}
    end
  end
  def updateBlockingFovs(map=$map)
    0.upto(MAP_HEIGHT-1) do |y|
      0.upto(MAP_WIDTH-1) do |x|
        TCOD.map_set_properties(@@obj_fov_map, x, y, !map[x,y].block_sight, !map[x,y].blocked)
      end
    end
  end
  def computeFovsForObjects

    updateBlockingFovs(self)
    self.objects.each{|o|
      TCOD.map_compute_fov(@@obj_fov_map, o.x, o.y, TORCH_RADIUS, FOV_LIGHT_WALLS, FOV_ALGO)
      seesOld=o.sees||[]
      o.sees=(self.objects-[o]).select{|o2| TCOD.map_is_in_fov(@@obj_fov_map, o2.x, o2.y) }
      (seesOld-o.sees).each{|vanishedObject|
        $events<<[o,:noLongerSees,vanishedObject]
      }
      (o.sees-seesOld).each{|newObject|
        $events<<[o,:nowSees,newObject]
      }
    }
  end

  def progressObjects
    objects.each{|o|
      if o.ai
        TCOD.map_compute_fov(@@obj_fov_map, o.x, o.y, TORCH_RADIUS, FOV_LIGHT_WALLS, FOV_ALGO)
        o.ai.call(o,Fov.new(@@obj_fov_map), self)
      end
    }
  end

end

