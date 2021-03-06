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

def actionAI(who,aiType,*params)
  lambda{||
         $map.select(who).each{|o|
    o.ai=ai(aiType,*params)
    o.aiData={:params=>params}
  }
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
  [room(0),1,place(:player,:center)],
  [room(0),1,place(:king,:top_middle,{:ally=>true})],
  [room(1),1,place(:guard,:top_left,{:ally=>true})],
  [room(1),1,place(:guard,:top_right,{:ally=>true})],
  #[room(1),1,place(:guard,:top_right,{:ally=>true, :ai=>[:guard,:sword]})],
  [room(1),1,place(:sword)],
  [room(4..10),0.3,place(:troll)]
]

$storyLine=[
  [event(:player, :enters, :level, 0), actionTalk("Welcome", "Welcome to the legend of Godrin.")],
  [event(:player, :talksTo, :king), actionTalk("King","The time has come. Bring me my sword. Soon they'll be here")],
  [event(:player, :takes, :sword), actionVanish(:king)],
  [event(:player, :walksInto, :wall), actionLog("Ouch")],
  [event(:player, :takes, :sword), actionAI(:guard,:follow, :player)],
]

