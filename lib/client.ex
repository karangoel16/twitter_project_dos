defmodule Project4.Client do
    use GenServer

    def connect(args) do
        #unless Node.alive?() do
          #we will use the 2nd element as ip address of the stuff
        Project4.Exdistutils.start_distributed(:project4,:ok)
        val="project4@"<>(args|>List.to_tuple|>elem(1))
        ping=Node.ping :"#{val}"
        if ping == :pang do
            IO.puts("Not able to Connect")
            Process.exit(self(),2);
        end
        #end
        IO.puts("connecting to node successful")
        Process.sleep(1000)
        #connect(args)
    end
    def genvalue({user,tweet},name) do
        reply=Enum.map(Map.get(user,name,MapSet.new)|>MapSet.to_list,fn(x)->
            Map.get(tweet,x)
        end)
        reply 
    end
    def start_link(args) do
        map=elem(GenServer.call({:global,:Server},{:server,""},:infinity),3)
        spawn(fn->IO.inspect {"new values while closed "<>Atom.to_string(args),genvalue(GenServer.call({:global,:Server},{:user,args|>Atom.to_string|>String.to_integer},:infinity),args|>Atom.to_string|>String.to_integer)} end)
        GenServer.start_link(__MODULE__,map,name: {:global,args})
    end

    def init(args) do
        {:ok,{args,%{},%{}}} #here the first elem is for the subsriber, #second elem is for the tweets
    end

  def handle_cast({msg,name},state) do
    reply=""
    case msg do
       :mentions->
         tup=GenServer.call({:global,:Server},{msg,name},:infinity)
         tweet=elem(tup,0)
         mentions=elem(tup,1)
        IO.inspect {"Tweets with mentions of "<>Integer.to_string(name), 
            Enum.map(MapSet.to_list(mentions),fn(x)->
                Map.get(tweet,x,"")  
            end)
        }
       :hashtags->
         tup=GenServer.call({:global,:Server},{msg,name},:infinity)
         tweet=elem(tup,0)
         hashtags=elem(tup,1)
         IO.inspect {"Tweets with mentions "<>name,
         Enum.map(Map.get(hashtags,name,MapSet.new)|>MapSet.to_list,fn(x)->
            Map.get(tweet,x,"")   
         end)}
    end
    {:noreply,state}
  end

    def handle_cast({msg,number,tweet_msg,name},state) do
        case msg do
            :tweet-> 
                IO.puts "tweet: from "<> Integer.to_string(name) <>" "<>tweet_msg
                tweet=elem(state,1)
                if Map.get(tweet,number) == nil do
                    GenServer.cast({:global,:Server},{:val,0,0,0})
                    #this is to increase the value of the tweet in the system
                    #GenServer.cast({:Server,Node.self()},{:user,number,name,0})
                    #this is to add the value of the node in the structure
                    map=SocialParser.extract(tweet_msg,[:hashtags,:mentions])
                    spawn(fn->Enum.map(Map.get(map,:hashtags,[]),fn(x)->
                        GenServer.cast({:global,:Server},{:hashtags_insert,x,number,0})
                    end)end)
                    spawn(fn->  
                    Enum.map(Map.get(map,:mentions,[]),fn(x)->
                        if GenServer.whereis({:global,String.replace_prefix(x,"@","")|>String.to_atom}) != nil do
                            GenServer.cast({:global,String.replace_prefix(x,"@","")|>String.to_atom},{:mention,number,tweet_msg,name})
                        end
                        GenServer.cast({:global,:Server},{:mentions,x,number,0})
                    end)end)
                    GenServer.cast({:global,:Server},{:tweets,number,tweet_msg,0})
                    GenServer.cast({:global,:Server},{:show,name,tweet_msg,number})
                    tweet=Map.put(tweet,number,tweet_msg)
                    state=Tuple.delete_at(state,1)|>Tuple.insert_at(1,tweet)
                end
            :retweet->
                tweet=elem(state,1)
                tweet_msg=Map.get(tweet,number,nil)
                if tweet_msg != nil do
                    GenServer.cast({:global,:Server},{:val,0,0,0})
                    IO.puts "RT: from "<>Integer.to_string(name)<>" "<>tweet_msg
                    GenServer.cast({:global,:Server},{:show,name,tweet_msg,number})
                end
            :mention->
                mention=elem(state,2)
                mention=Map.put(mention,number,tweet_msg)
                state=Tuple.delete_at(state,2)|>Tuple.insert_at(2,mention)
            :subscribe->
                #we are adding subscribers here for the functions to work
                map=elem(state,0)
                map=MapSet.new(number)
                state=Tuple.delete_at(state,0)|>Tuple.insert_at(0,map)
            :show->
                if :rand.uniform(50)==2 do
                    GenServer.cast({:global,name|>Integer.to_string|>String.to_atom},{:retweet,number,tweet_msg,name})
                end
                if :rand.uniform(100)==3 do
                    map=SocialParser.extract(tweet_msg,[:hashtags,:mentions])
                    GenServer.cast({:global,name|>Integer.to_string|>String.to_atom},{:hashtags,List.first(Map.get(map,:hashtags,[]))})
                end
                if :rand.uniform(100)==3 do
                    map=SocialParser.extract(tweet_msg,[:hashtags,:mentions])
                    GenServer.cast({:global,name|>Integer.to_string|>String.to_atom},{:mentions,List.first(Map.get(map,:mentions,[]))|>String.replace_prefix("@","")|>String.to_integer})
                end
                tweet=elem(state,1)
                tweet=Map.put(tweet,number,tweet_msg)
                state=Tuple.delete_at(state,1)|>Tuple.insert_at(1,tweet)
        end        
    {:noreply,state}
    end
end