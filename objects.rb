require_relative './ai.rb'

Obj=Struct.new(:x, :y, :name, :char, :type, :color, :block, :block_view, :hp, :ally, :sees, :stackable, :inventory, :ai, :aiData)
class Obj
  def pos
    Pos.new(self.x, self.y)
  end
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
  def pickup(map)
    map.objects(x,y).select{|o|o!=self}.each{|o|
      #FIXME: check weight and pickable ?
      map.objects.delete(o)
      self.inventory.push(o)
      o.x=-1
      o.y=-1
      $events<<[self.type,:takes,o.type]
    }
  end
end

module FightingObj
  def fight(obj)
  end
end

def object(pos,type,attrs={})
  c=TCOD::Color
  d=Struct.new(:name, :tile, :color, :probability, :hp, :stackable, :ally, :ai)

  ts=[
    d.new('King' ,'K',c::YELLOW, 0, 90, false, true, :monster),
    d.new('Sword', 's', c::WHITE, 0, 0, true, nil),
    d.new('Player', '@',c::WHITE, 0, 20, false, true),
    d.new('Orc', 'o', c::DESATURATED_GREEN, 0.8, 5, false, false, :monster),
    d.new('Troll', 'T', c::DARKER_GREEN, 1, 10, false, false, :monster),
    d.new('Guard', 'G', c::YELLOW, 0, 60, false, true, :saveking),
  ]

  t={}
  ts.each{|x|
    t[x.name.downcase.to_sym]=x
  }
  t=t[type]
  puts "CREATE #{type}"
  o=Obj.new(*pos, t.name, t.tile, type, t.color, (not t.stackable), true,
            t.hp, t.ally, [], t.stackable, [], ai(*[attrs[:ai]||t.ai].flatten))

  attrs.each{|k,v|
    o.send(k.to_s+"=",v) unless k==:ai
  }

  o
end
