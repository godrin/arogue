Event=Struct.new(:name,:data)

def room(*args)
  args
end

def event(*args)
  lambda{|rawEvent|
    match=true
    i=-1
    rawEvent.select{|x|
      i+=1
      case x
      when Symbol, Numeric
        x!=args[i]
      when Obj
        x.type!=args[i]
      else
        true
      end
    }.length==0
  }
end

def actionTalk(who,talk)
  lambda{||
    $overlays << StoryView.new(who,talk)
  }
end

def actionVanish(who)
  lambda{||
         $map.objects.select!{|o|o.type!=who}
  }
end

def actionLog(text)
  lambda{||
         puts text
  }
end

$architect=[
  [room(1),:king],
  [room(2),:sword]
]

$storyLine=[
  [event(:player, :enters, :level, 0), actionTalk("Welcome", "Welcome to the legend of Godrin.")],
  [event(:player, :talksTo, :king), actionTalk("King","The time has come. Bring me my sword. Soon they'll be here")],
  [event(:player, :noLongerSees, :king), actionVanish(:king)],
  [event(:player, :walksInto, :wall), actionLog("Ouch")],
]
