
class Screen
  def initialize(con)
    @con = con
  end
  def rect_text(text,color,x,y,w,h)
    TCOD.console_set_default_foreground($con, color)
    TCOD.console_print_rect(@con,x,y,w,h,text)
  end

end
