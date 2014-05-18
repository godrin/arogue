require 'pp'

def rgb(r, g, b)
  TCOD::Color.rgb(r, g, b)
end

TileDef=Struct.new(:char, :fg, :bg)

MATERIALS={
  :rock=>rgb(200,200,200),
  :lehm=>rgb(180,140,100)
}

TILES={
  :wall=>TileDef.new('#',rgb(0,0,0),MATERIALS[:lehm]), #,MATERIALS[:lehm]*0.8),
  :ground=>TileDef.new('.',rgb(70,60,41),rgb(0,0,0))
}

def scaleRgb(c,var)
  r,g,b=c.values
  x,y,z=var
  #pp "S",x,y,z,r,g,b
  TCOD::Color.rgb((r*x).to_i,(g*y).to_i,(b*z).to_i)
end

def rndRgb(c)
  r,g,b=c.values
  f=rand*0.4+0.8
  r=(r*f).to_i
  g=(g*f).to_i
  b=(b*f).to_i
  c=TCOD::Color.rgb(r,g,b)
  c
end
