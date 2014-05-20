#!/usr/bin/env ruby

require 'libtcod'
require_relative './colors.rb'
require_relative './architect.rb'

#actual size of the window
SCREEN_WIDTH = 50
SCREEN_HEIGHT = 17

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

class Story
  def initialize
    @text=">>Yksjdhf sdfkjhsdf ksjfdh dsfkj hkjsdhf sdks sf <<"
    @title="King"
    @r=Rect.new(5,2,30,4)
    @color=TCOD::Color.rgb(150,150,150)
    @bgColor=TCOD::Color.rgb(20,20,20)
    @titleColor=TCOD::Color.rgb(180,150,150)
  end
  def  draw
    TCOD.console_set_default_background($con, @bgColor)
    TCOD.console_set_default_foreground($con, @titleColor)
    TCOD.console_rect($con,@r.x1,@r.y1,@r.w,@r.h,false,TCOD::BKGND_DARKEN)
    TCOD.console_print_rect($con,*@r.xywh,@title)
    TCOD.console_set_default_foreground($con, @color)
    h= TCOD.console_print_rect($con,*@r.shrink(1).xywh,@text)
    if h>@r.h
      puts "ERROR"
    end
  end

end

class ObjPainter

  def draw(what)
    #only show if it's visible to the $player
    if TCOD.map_is_in_fov($fov_map, what.x, what.y)
      #set the color and then draw the character that represents this object at its position
      TCOD.console_set_default_foreground($con, what.color)
      TCOD.console_put_char($con, what.x, what.y, what.char.ord, TCOD::BKGND_NONE)
    end
  end
end

class AI
end



def render_all(map)
  if $fov_recompute or true
    #recompute FOV if needed(the $player moved or something)
    $fov_recompute = false
    TCOD.map_compute_fov($fov_map, map.player.x, map.player.y, TORCH_RADIUS, FOV_LIGHT_WALLS, FOV_ALGO)

    #go through all tiles, and set their background color according to the FOV
    0.upto(MAP_HEIGHT-1) do |y|
      0.upto(MAP_WIDTH-1) do |x|
        visible = TCOD.map_is_in_fov($fov_map, x, y)
        cell = map[x,y]
        fgColor=cell.fgColor
        bgColor=cell.bgColor

        explored=map[x,y].explored
        if visible or explored 
          if not visible
            fgColor=fgColor*0.5
            bgColor=bgColor*0.5
          else
            map[x,y].explored = true
          end
          TCOD.console_put_char_ex($con, x, y, cell.char.ord, fgColor, bgColor )
        end
      end
    end
  end

  objPainter=ObjPainter.new

  #draw all objects in the list
  $objects.each do |object|
    objPainter.draw(object)
  end

  $overlays.each do |overlay|
    overlay.draw
  end

  #blit the contents of "con" to the root console
  TCOD.console_blit($con, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, nil, 0, 0, 1.0, 1.0)
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


  if $overlays.length>0
    if TCOD.console_is_key_pressed(TCOD::KEY_SPACE)
      $overlays.clear
    end
    #@overlays[0]
  else
    player=map.player
    #movement keys
    if TCOD.console_is_key_pressed(TCOD::KEY_UP)
      player.move(0, -1)
      $fov_recompute = true
    elsif TCOD.console_is_key_pressed(TCOD::KEY_DOWN)
      player.move(0, 1)
      $fov_recompute = true
    elsif TCOD.console_is_key_pressed(TCOD::KEY_LEFT)
      player.move(-1, 0)
      $fov_recompute = true
    elsif TCOD.console_is_key_pressed(TCOD::KEY_RIGHT)
      player.move(1, 0)
      $fov_recompute = true
    end
  end
  false
end


#############################################
# Initialization & Main Loop
#############################################

#note that we must specify the number of tiles on the font, which was enlarged a bit
TCOD.console_set_custom_font(File.join(File.dirname(__FILE__), 'font','font-11.png'), TCOD::FONT_TYPE_GREYSCALE | TCOD::FONT_LAYOUT_TCOD, 16, 16)
TCOD.console_init_root(SCREEN_WIDTH, SCREEN_HEIGHT, 'story roguelike', false, TCOD::RENDERER_SDL)
TCOD.sys_set_fps(LIMIT_FPS)
$con = TCOD.console_new(SCREEN_WIDTH, SCREEN_HEIGHT)


TCOD.console_map_ascii_codes_to_font(0, 255, 0, 0) 

#create object representing the $player

$story = Story.new
#the list of objects with just the $player
$overlays = [$story]

#generate $map(at this point it's not drawn to the screen)
mapInfo = make_map
$map=mapInfo
$objects = mapInfo.objects
$player=mapInfo.objects.find{|o|o.type==:player}
#pp $player
#exit


#create the FOV $map, according to the generated $map
$fov_map = TCOD.map_new(MAP_WIDTH, MAP_HEIGHT)
0.upto(MAP_HEIGHT-1) do |y|
  0.upto(MAP_WIDTH-1) do |x|
    TCOD.map_set_properties($fov_map, x, y, !$map[x,y].block_sight, !$map[x,y].blocked)
  end
end

$fov_recompute = true

trap('SIGINT') { exit! }

until TCOD.console_is_window_closed()

  #render the screen
  render_all($map)

  TCOD.console_flush()

  #handle keys and exit game if needed
  will_exit = handle_keys($map)
  break if will_exit
end
# hard exit, because it hangs otherwise
TCOD.console_set_fullscreen(false)
exit!
