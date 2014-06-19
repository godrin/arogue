
module Path
  P=Struct.new(:positions, :goneweight, :rest)

  class P
    def weight
      goneweight+rest
    end
    def <=>(o)
      weight<=>o.weight
    end
  end

  module Finder
    def findPath(p0, p1)
      paths=[P.new([p0],0,(p1-p0).len)]

      tries=0

      loop do
        cur=paths.shift

        lastpos=cur.positions[-1]
        lastpos.neighbors.each{|n|
          if n==p1
            return cur.positions+[n]
          end
          blockedBy=self.blocked(*n)
          if not blockedBy
            np=P.new(cur.positions+[n],cur.goneweight+1,(p1-n).len)
            paths<<np
          elsif blockedBy!=[:wall]
            np=P.new(cur.positions+[n],cur.goneweight+3,(p1-n).len)
            paths<<np
          end
        }

        paths.sort!

        tries+=1
        break if tries>30
      end
      paths[0].positions # take best path, even if it does not yet reach the destination
    end
  end
end
