defmodule Project4.Client do
    use GenServer

    def start_link(args) do
        #map=elem(GenServer.call({:Server,Node.self()},:msg,:infinity),3)
        GenServer.start_link(__MODULE__,Map.get(map,args|>Atom.to_string|>String.to_integer,MapSet.new),name: args)
    end

    def init(args) do
        {:ok,{args,%{},%{}}} #here the first elem is for the subsriber, #second elem is for the tweets
    end

  def handle_call(msg,_from,state) do
    {:reply,state,state}
  end
    def handle_cast({msg,number,tweet_msg,name},state) do
        case msg do
            :tweet-> 
                IO.puts tweet_msg
                tweet=elem(state,1)
                if Map.get(tweet,number) == nil do
                    GenServer.cast({:Server,Node.self()},{:user,number,name}) #this is to add the value of the node in the structure
                    map=SocialParser.extract(tweet_msg,[:hashtags,:mentions])
                    Enum.map(Map.get(map,:hashtags,[]),fn(x)->
                        GenServer.cast({:Server,Node.self()},{:hashtags_insert,x,number})
                    end)
                    Enum.map(Map.get(map,:mentions,[]),fn(x)->
                        if GenServer.whereis({String.replace_prefix(x,"@","")|>String.to_atom,Node.self()}) != nil do
                            GenServer.cast({String.replace_prefix(x,"@","")|>String.to_atom,Node.self()},{:mention,number,tweet_msg,name})
                        end
                        GenServer.cast({:Server,Node.self()},{:mentions,x,number})
                    end)
                    GenServer.cast({:Server,Node.self()},{:tweets,number,tweet_msg})
                    tweet=Map.put(tweet,number,tweet_msg)
                    Enum.map(elem(state,0)|>MapSet.to_list,fn(x)->
                        if GenServer.whereis({x|>Integer.to_string|>String.to_atom,Node.self()}) != nil do
                            GenServer.cast({x|>Integer.to_string|>String.to_atom,Node.self()},{:show,number,tweet_msg,name})
                        end
                    end)
                    state=Tuple.delete_at(state,1)|>Tuple.insert_at(1,tweet)
                end
            :retweet->
                tweet=elem(state,1)
                tweet_msg=Map.get(tweet,number,nil)
                if tweet_msg != nil do
                    Enum.map(elem(state,0)|>MapSet.to_list,fn(x)->
                        if GenServer.whereis({x|>Integer.to_string|>String.to_atom,Node.self()}) != nil do
                            GenServer.cast({x|>Integer.to_string|>String.to_atom,Node.self()},{:show,number,tweet_msg,name})
                        end
                    end)
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
                tweet=elem(state,1)
                tweet=Map.put(tweet,number,tweet_msg)
                state=Tuple.delete_at(state,1)|>Tuple.insert_at(1,tweet)
        end        
    {:noreply,state}
    end
end