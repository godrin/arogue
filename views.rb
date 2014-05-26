
class StoryView
  def initialize
    @text=">>Yksjdhf sdfkjhsdf ksjfdh dsfkj hkjsdhf sdks sf <<"
    @title="King"
    @r=Rect.new(5,2,30,4)
    #@r=Rect.new(0,0,SCREEN_WIDTH,SCREEN_HEIGHT) #:5,2,30,4)
    @color=TCOD::Color.rgb(150,150,150)
    @bgColor=TCOD::Color.rgb(20,20,20)
    @titleColor=TCOD::Color.rgb(180,150,150)
  end
  def  draw
    TCOD.console_set_default_background($con, @bgColor)
    TCOD.console_rect($con,@r.x1,@r.y1,@r.w,@r.h,false,TCOD::BKGND_DARKEN)

    $screen.rect_text(@title,@titleColor,nil,*@r.xywh)
    $screen.rect_text(@text,@color,nil,*@r.shrink(1).xywh)
  end
end

class ObjNameView
  def initialize(obj, pos)
    @obj=obj
    @pos=pos
    @r=Rect.new(*pos,15,1)
  end

  def draw
    text=@obj.char+": "+@obj.name
    TCOD.console_set_default_foreground($con, TCOD::Color::GREY)
    TCOD.console_print_rect($con,*@r.xywh,text)
    TCOD.console_set_default_background($con, TCOD::Color::DARK_BLUE)
    TCOD.console_rect($con,*@r.moved(0,1).xywh,false,TCOD::BKGND_SET)
    
  end
end

class ObjPainter

  # returns true if object was painted
  def draw(what)
    #only show if it's visible to the $player
    if TCOD.map_is_in_fov($fov_map, what.x, what.y)
      #set the color and then draw the character that represents this object at its position
      TCOD.console_set_default_foreground($con, what.color)
      TCOD.console_put_char($con, what.x, what.y, what.char.ord, TCOD::BKGND_NONE)
      return true
    end
    false
  end
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
        else
          fgColor=bgColor=TCOD::Color::BLACK
          c=" "
          TCOD.console_put_char_ex($con, x, y, c.ord, fgColor, bgColor )
        end
      end
    end
  end

  objPainter=ObjPainter.new
  objDisplays=[]
  py=6

  #draw all objects in the list
  $objects.each do |object|
    if objPainter.draw(object)
      objDisplays<<ObjNameView.new(object,Pos.new(1,py))
      py+=4
    end
  end

  (objDisplays+$overlays).each do |overlay|
    overlay.draw
  end

  #blit the contents of "con" to the root console
  TCOD.console_blit($con, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, nil, 0, 0, 1.0, 1.0)
  TCOD.console_flush()
end

def initDisplay

  #note that we must specify the number of tiles on the font, which was enlarged a bit
  TCOD.console_set_custom_font(File.join(File.dirname(__FILE__), 'font','font-11.png'), TCOD::FONT_TYPE_GREYSCALE | TCOD::FONT_LAYOUT_TCOD, 16, 16)
  TCOD.console_init_root(SCREEN_WIDTH, SCREEN_HEIGHT, 'story roguelike', false, TCOD::RENDERER_SDL)
  TCOD.sys_set_fps(LIMIT_FPS)
  $con = TCOD.console_new(SCREEN_WIDTH, SCREEN_HEIGHT)
  $screen = Screen.new($con)

  TCOD.console_map_ascii_codes_to_font(0, 255, 0, 0) 

end

def initFovInit
#create the FOV $map, according to the generated $map
$fov_map = TCOD.map_new(MAP_WIDTH, MAP_HEIGHT)
0.upto(MAP_HEIGHT-1) do |y|
  0.upto(MAP_WIDTH-1) do |x|
    TCOD.map_set_properties($fov_map, x, y, !$map[x,y].block_sight, !$map[x,y].blocked)
  end
end

$fov_recompute = true

end
