

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
