
Obj=Struct.new(:x, :y, :name, :char, :type, :color, :block, :block_view, :hp, :ally, :sees, :stackable)
class Obj

  def move (map, dx, dy)
    #move by the given amount, if the destination.equal? not blocked
    blocked=map.blocked(self.x + dx,self.y + dy)
    if not blocked
      self.x += dx
      self.y += dy
    else
      blocked.each{|obj|
        if obj.is_a?(Obj)
          if obj.ally
            $events<<[self,:talksTo,obj]
          end
        else
          $events<<[self,:walksInto,obj]
        end
      }
    end
  end
end

module FightingObj
  def fight(obj)
  end
end

def object(pos,type,attrs={})
  c=TCOD::Color
  d=Struct.new(:name, :tile, :color, :probability, :hp, :stackable)

  ts=[
    d.new('King' ,'K',c::YELLOW, 0, 90, false),
    d.new('Sword', 's', c::WHITE, 0, 0, true),
    d.new('Player', '@',c::WHITE, 0, 20, false),
    d.new('Orc', 'o', c::DESATURATED_GREEN, 0.8, 5, false),
    d.new('Troll', 'T', c::DARKER_GREEN, 1, 10, false),
  ]

  t={}
  ts.each{|x|
    t[x.name.downcase.to_sym]=x
  }
  t=t[type]
  puts "CREATE #{type}"
  o=Obj.new(*pos, t.name, t.tile, type, t.color, (not t.stackable), true, [], t.stackable)

  attrs.each{|k,v|
    o.send(k.to_s+"=",v)
  }


  o
end
