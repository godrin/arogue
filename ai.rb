
class AI
end

class MonsterAI<AI
  NEIGHBORS=[[-1,0],[0,-1],[1,0],[0,1]]
  def call(obj, fov, map)
    n=NEIGHBORS.select{|n|fov[n[0]+obj.x,n[1]+obj.y]}.shuffle[0]
    obj.move(map, n[0],n[1]) if n
  end
end

class GuardAI<AI
  def initialize(what)
    @what=what
  end
  def call(obj, fov, map)
    @target||=map.find(@what)
    if fov[@target.x,@target.y]
      puts "OK"
    else
      puts "AWY ?"
    end
    puts "GUARD"
    @what
  end
end

module AIs
  def self.randomWalk(obj, fov, map)
    n=[[-1,0],[0,-1],[1,0],[0,1]].select{|n|fov[n[0]+obj.x,n[1]+obj.y]}.shuffle[0]
    obj.move(map, n[0],n[1]) if n
  end


  def self.follow(obj, fov, map)
    puts "FOLLOW"
    data=obj.aiData
    targetSym=data[:params][0]
    target=map.find(targetSym)
    path=map.findPath(obj.pos, target.pos)
    obj.move(map,*path[0])

#    pp obj.aiData, target
  end

  def self.saveKing(obj, fov, map)
     
  end
end

def ai(sym=nil,*args)
  map={
    :monster=>MonsterAI,
    :guard=>GuardAI,
    :monster2=>:randomWalk,
    :saveKing=>:saveKing,
    :follow=>:follow
  }
  kind=map[sym]
  puts "NEW AI #{sym}"
  return nil unless kind
  case kind
  when Class
    kind.new(*args)
  when Symbol
    AIs.method(kind)
  end
end


