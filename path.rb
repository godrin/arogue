
module Path
  P=Struct.new(:positions, :rest)

  class P
    def weight
      positions.length+rest
    end
    def <=>(o)
      weight<=>o.weight
    end
  end

  module Finder
    def findPath(p0, p1)

      paths=[P.new([p0],(p1-p0).len)]

      loop do
        cur=paths.shift

        lastpos=cur.positions[-1]
        lastpos.neighbors.each{|n|
          unless self.blocked(*n)
            np=P.new(cur.positions+[n],(p1-n).len)
            if n==p1
              return np.positions
            end
            paths<<np
          end
        }

        paths.sort!

      end
      raise "no path found"

    end
  end
end
