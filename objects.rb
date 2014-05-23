
Obj=Struct.new(:x, :y, :name, :char, :type, :color, :map, :block, :block_view, :hp, :ally)
class Obj

  def move (dx, dy)
    #move by the given amount, if the destination.equal? not blocked
    if not self.map.blocked(self.x + dx,self.y + dy)
      self.x += dx
      self.y += dy
    end
  end
end

module FightingObj
  def fight(obj)
  end
end

def object(pos,type,attrs={})
  c=TCOD::Color
  d=Struct.new(:name, :tile, :color, :probability, :hp)

  ts=[
    d.new('King' ,'K',c::YELLOW, 0, 90),
    d.new('Player', '@',c::WHITE, 0, 20),
    d.new('Orc', 'o', c::DESATURATED_GREEN, 0.8, 5),
    d.new('Troll', 'T', c::DARKER_GREEN, 1, 10)
  ]

  t={}
  ts.each{|x|
    t[x.name.downcase.to_sym]=x
  }
  t=t[type]
  
  o=Obj.new(*pos, t.name, t.tile, type, t.color, nil, true, true)

  attrs.each{|k,v|
    o.send(k.to_s+"=",v)
  }


  o
end
