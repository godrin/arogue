Event=Struct.new(:name,:data)

def room(no)
  no
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

def place(what,where=nil,args={})
  lambda{|room|
    pos=where || :anywhere
    object(room.send(pos), what,args )
  }
end

$architect=[
  [room(1),1,place(:player,:center)],
  [room(1),1,place(:king,:top_middle,{:ally=>true})],
  [room(3),1,place(:sword)],
  [room(5..10),0.3,place(:troll)]
]

$storyLine=[
  [event(:player, :enters, :level, 0), actionTalk("Welcome", "Welcome to the legend of Godrin.")],
  [event(:player, :talksTo, :king), actionTalk("King","The time has come. Bring me my sword. Soon they'll be here")],
  [event(:player, :noLongerSees, :king), actionVanish(:king)],
  [event(:player, :walksInto, :wall), actionLog("Ouch")],
]

