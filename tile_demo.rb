#!/usr/bin/env ruby

require 'libtcod'
require_relative './colors.rb'
require_relative './architect.rb'
require_relative './screen.rb'
require_relative './views.rb'

#actual size of the window
SCREEN_WIDTH = 80
SCREEN_HEIGHT = 30

#size of the $map
MAP_WIDTH = SCREEN_WIDTH
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
  def [](x,y)
    self.map[x][y]
  end
  def player
    @player||=objects.find{|o|o.type==:player}
  end
  def blocked(x,y)
    self[x,y].blocked or begin
    self.objects.find{|o|o.x==x and o.y==y and o.block }
  end
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

  story=$overlays.find{|o|o.is_a?(Story)}
  if story
    if TCOD.console_is_key_pressed(TCOD::KEY_SPACE)
      $overlays.select!{|o|not o.is_a?(Story)} #.clear
    end
    #@overlays[0]
  else
    player=map.player
    #movement keys
    if TCOD.console_is_key_pressed(TCOD::KEY_UP)
      player.move(0, -1)
    elsif TCOD.console_is_key_pressed(TCOD::KEY_DOWN)
      player.move(0, 1)
    elsif TCOD.console_is_key_pressed(TCOD::KEY_LEFT)
      player.move(-1, 0)
    elsif TCOD.console_is_key_pressed(TCOD::KEY_RIGHT)
      player.move(1, 0)
    end
  end
  false
end


#############################################
# Initialization & Main Loop
#############################################

initDisplay

$story = Story.new
#the list of objects with just the $player

#generate $map(at this point it's not drawn to the screen)
mapInfo = make_map
$map=mapInfo
$objects = mapInfo.objects
$player=mapInfo.objects.find{|o|o.type==:player}
$overlays = [$story]


initFovInit

trap('SIGINT') { exit! }

until TCOD.console_is_window_closed()

  #render the screen
  render_all($map)

  #handle keys and exit game if needed
  will_exit = handle_keys($map)
  break if will_exit
end
# hard exit, because it hangs otherwise
TCOD.console_set_fullscreen(false)
exit!
