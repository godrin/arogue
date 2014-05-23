
class Screen
  def initialize(con)
    @con = con
  end
  def rect_text(text,color,bgcolor,x,y,w,h)
    TCOD.console_set_default_foreground($con, color)
    bgMode=TCOD::BKGND_NONE
    if bgcolor
      TCOD.console_set_default_background($con, bgcolor)
      bgMode=TCOD::BKGND_SET
    end
    align=TCOD::LEFT
    TCOD.console_print_rect_ex(@con,x,y,w,h,bgMode,align,text)
  end

end
