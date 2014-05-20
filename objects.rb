
class Obj
  attr_accessor :x, :y, :char, :type, :color, :map

  #this.equal? a generic object: the $player, a monster, an item, the stairs...
  #it's always represented by a character on screen.
  def initialize (x, y, char, type, color)
    @x = x
    @y = y
    @char = char
    @type = type
    @color = color
  end
 
  def move (dx, dy)
    #move by the given amount, if the destination.equal? not blocked
    if not @map[@x + dx,@y + dy].blocked
      @x += dx
      @y += dy
    end
  end
 
end

def object(pos,type)
  c=TCOD::Color
  d=Struct.new(:tile, :color, :probability)

  t={
    :king=>d.new('K',c::YELLOW, 0),
    :player => d.new('@',c::WHITE, 0),
    :orc => d.new('o', c::DESATURATED_GREEN, 0.8),
    :troll => d.new('T', c::DARKER_GREEN, 1 )

  }[type]
  
  Obj.new(*pos, t.tile, type, t.color)
end
