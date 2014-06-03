#!/usr/bin/env ruby

require 'libtcod'
require_relative './colors.rb'
require_relative './architect.rb'
require_relative './screen.rb'
require_relative './views.rb'
require_relative './event.rb'

#actual size of the window
SCREEN_WIDTH = 80
SCREEN_HEIGHT = 30

#size of the $map
MAP_WIDTH = SCREEN_WIDTH - 20
MAP_HEIGHT = SCREEN_HEIGHT
MAX_ROOM_MONSTERS = 3
#parameters for dungeon generator
ROOM_MAX_SIZE = 10
ROOM_MIN_SIZE = 6
MAX_ROOMS = 30
REAL_TIME = false

FOV_ALGO = 3+3 # 0  #default FOV algorithm
FOV_LIGHT_WALLS = true  #light walls or not
TORCH_RADIUS = 10

LIMIT_FPS = 20  #20 frames-per-second maximum

KING_TILE = 'K'.ord
MAGE_TILE = '@'.ord
SKELETON_TILE = 's'.ord

class Tile
  attr_accessor :blocked, :explored, :block_sight
  attr_reader :colorVariant

  #a tile of the $map and its properties
  def initialize(blocked, block_sight = nil)
    @blocked = blocked

    #all tiles start unexplored
    @explored = false

    #by default, if a tile.equal? blocked, it also blocks sight
    if block_sight.nil?
      @block_sight = blocked
    else
      @block_sight = block_sight
    end

    @colorVariant=3.times.map{||rand*0.2+0.9}
  end

  def material
    @block_sight ? :wall : :ground
  end

  def tile
    TILES[material]
  end

  def char
    tile.char
  end

  def fgColor
    scaleRgb(tile.fg, @colorVariant)
  end
  def bgColor
    scaleRgb(tile.bg, @colorVariant)
  end
end

class Map
  @@obj_fov_map = TCOD.map_new(MAP_WIDTH, MAP_HEIGHT)

  def [](x,y=nil)
    if x.is_a?(Symbol)
      super(x)
    else
      self.map[x][y]
    end
  end
  def player
    @player||=objects.find{|o|o.type==:player}
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
end


class AI
end

def handle_keys(map)
  if REAL_TIME
    key = TCOD.console_check_for_keypress(TCOD::KEY_PRESSED)  #real-time
  else
    key = TCOD.console_wait_for_keypress(true)  #turn-based
  end
  if key.vk == TCOD::KEY_ENTER #and key.lalt
    #Alt+Enter: toggle fullscreen
    TCOD.console_set_fullscreen(!TCOD.console_is_fullscreen)
  elsif key.vk == TCOD::KEY_ESCAPE
    return true  #exit game
  end

  story=$overlays.find{|o|o.is_a?(StoryView)}
  if story
    if TCOD.console_is_key_pressed(TCOD::KEY_SPACE)
      $overlays.select!{|o|not o.is_a?(StoryView)} #.clear
    end
    #@overlays[0]
  else
    player=map.player
    #movement keys
    # use from event
    if key.pressed
      case key.vk
      when TCOD::KEY_UP, TCOD::KEY_KP8
        player.move(map, 0,-1)
      when TCOD::KEY_DOWN, TCOD::KEY_KP2
        player.move(map,0,1)
      when TCOD::KEY_LEFT, TCOD::KEY_KP4
        player.move(map,-1,0)
      when TCOD::KEY_RIGHT, TCOD::KEY_KP6
        player.move(map,1,0)
      when TCOD::KEY_UP, TCOD::KEY_KP1
        player.move(map,-1,1)
      when TCOD::KEY_UP, TCOD::KEY_KP3
        player.move(map,1,1)
      when TCOD::KEY_UP, TCOD::KEY_KP7
        player.move(map,-1,-1)
      when TCOD::KEY_UP, TCOD::KEY_KP9
        player.move(map,1,-1)
      else
        puts "UNKNOWN KEY #{key.vk}"
      end
    end

  end
  false
end

def progressStory
  $map.computeFovsForObjects
  $events.each{|ev|
    $storyLine.each{|rule|
      if rule[0].call(ev)
        rule[1].call
        #puts "RULE MATCH"
      end
    }
  }

  $events=[]

end


#############################################
# Initialization & Main Loop
#############################################

initDisplay

$story = StoryView.new
#the list of objects with just the $player

#generate $map(at this point it's not drawn to the screen)
mapInfo = make_map
$map=mapInfo
$objects = mapInfo.objects
$player=mapInfo.objects.find{|o|o.type==:player}
$overlays = [] #$story]
$events= []

mapView=MapView.new(mapInfo, Rect.new(20,0,SCREEN_WIDTH-21,SCREEN_HEIGHT-1))

trap('SIGINT') { exit! }

$events << [:player, :enters, :level, 0]

until TCOD.console_is_window_closed()
  progressStory
  
  #render the screen
  render_all($map, mapView)

  #handle keys and exit game if needed
  will_exit = handle_keys($map)
  break if will_exit
end
# hard exit, because it hangs otherwise
TCOD.console_set_fullscreen(false)
exit!

