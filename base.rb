
class Range
  def rand
    if self.max==self.min
      return self.min
    else
      Kernel::rand(self.max-self.min)+self.min
    end
  end
end

Pos=Struct.new(:x,:y)
class Pos
  def +(p)
    Pos.new(self.x+p.x,self.y+p.y)
  end
  def -(p)
    Pos.new(self.x-p.x,self.y-p.y)
  end

  def len
    Math.sqrt(self.x*self.x + self.y*self.y)
  end
  def neighbors
    [[-1,0],[-1,-1],[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1]].map{|a,b|
      Pos.new(self.x+a,self.y+b)
    }
  end
  def ==(o)
    self.x==o.x and self.y==o.y
  end
end

class Rect
  attr_accessor :x1, :y1, :x2, :y2, :name
  #a rectangle on the map. used to characterize a room.
  def initialize (x, y, w, h, name="")
    @name=name
    if w<0
      w*=-1
      x-=w
    end
    if h<0
      h*=-1
      y-=h
    end
    @x1 = x
    @y1 = y
    @x2 = x + w
    @y2 = y + h
  end

  def self.fromPos(x1,y1,x2,y2)
    Rect.new([x1,x2].min,[y1,y2].min,(x2-x1).abs,(y2-y1).abs)
  end

  def topleft
    Pos.new(@x1,@y1)
  end
 
  def center
    center_x = (@x1 + @x2) / 2
    center_y = (@y1 + @y2) / 2
    Pos.new(center_x, center_y)
  end
  def anywhere
    Pos.new(@x1+rand(w-1)+1,@y1+rand(h-1)+1)
  end
  def top_middle
    Pos.new((@x1+@x2)/2,@y1+1)
  end
  def top_left
    Pos.new(@x1,@y1)
  end
  def top_right
    Pos.new(@x2,@y1)
  end
  def shrink(d)
    Rect.new(x1+d,y1+d,w-2*d,h-2*d)
  end

  def moved(x,y)
    Rect.new(x1+x,y1+y,w,h)
  end
  def contains(pos)
    @x1<=pos.x and @x2>pos.x and @y1<=pos.y and @y2>pos.y
  end

  def containsRect(rect)
    @x1<=rect.x1 and @y1<=rect.y1 and @x2>=rect.x2 and @y2>=rect.y2
  end

  def borderPositions
    ((@x1..@x2).map{|x|
      [Pos.new(x,@y1),Pos.new(x,@y2)]
    }+
    (@y1..@y2).map{|y|
      [Pos.new(@x1,y),Pos.new(@x2,y)]
    }).flatten
  end

  def intersect (other)
    #returns true if this rectangle intersects with another one
    return (@x1 <= other.x2 and @x2 >= other.x1 and
            @y1 <= other.y2 and @y2 >= other.y1)
  end

  def intersects_list(list)
    list.select{|other|
      self.intersect(other)
    }.length >0
  end

  def w
    @x2-@x1
  end
  def h
    @y2-@y1
  end
  def xywh
    [@x1,@y1,w,h]
  end

  def each
    (@x1..@x2).each{|x|
      (@y1..@y2).each{|y|
        yield Pos.new(x,y)
      }
    }
  end
end

