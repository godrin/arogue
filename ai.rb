
class AI
end

class MonsterAI<AI
  NEIGHBORS=[[-1,0],[0,-1],[1,0],[0,1]]
  def call(obj, fov, map)
    n=NEIGHBORS.select{|n|fov[n[0]+obj.x,n[1]+obj.y]}.shuffle[0]
    obj.move(map, n[0],n[1]) if n
  end
end

def ai(sym)
  case sym
  when :monster
    MonsterAI.new
  end
end
