defmodule Project4.Client do
    use GenServer

    def start_link(args) do
        map=elem(GenServer.call({:Server,Node.self()},:msg),3)
        GenServer.start_link(__MODULE__,{:ok,Map.get(map,args|>Atom.to_string|>String.to_integer,MapSet.new)},name: args)
    end

    def init(args) do
        {:ok,{args,%{},%{}}} #here the first elem is for the subsriber, #second elem is for the tweets
    end
    def handle_cast({msg,number,tweet_msg},state) do
        case msg do
            :tweet-> 
                tweet=elem(state,1)
                if Map.get(tweet,number) == nil do
                    map=SocialParser.extract(tweet_msg,[:hashtags,:mentions])
                    Enum.map(Map.get(map,:hashtags,[]),fn(x)->
                        GenServer.cast({:Server,Node.self()},{:hashtags_insert,x,number})
                    end)
                    Enum.map(Map.get(map,:mentions,[]),fn(x)->
                        if GenServer.whereis({String.replace_prefix(x,"@","")|>String.to_atom,Node.self()}) != nil do
                            GenServer.cast({String.replace_prefix(x,"@","")|>String.to_atom,Node.self()},{msg,number,tweet_msg})
                        end
                        GenServer.cast({:Server,Node.self()},{:mentions,x,number})
                    end)
                    GenServer.cast({:Server,Node.self()},{:tweets,number,tweet_msg})
                    tweet=Map.put(tweet,number,tweet_msg)
                    Enum.map(elem(state,0)|>Map.keys,fn(x)->
                        if GenServer.whereis({x|>Integer.to_string|>String.to_atom,Node.self()}) != nil do
                            GenServer.cast({x|>Integer.to_string|>String.to_atom,Node.self()},{msg,number,tweet_msg})
                        end
                    end)
                    state=Tuple.delete_at(state,1)|>Tuple.insert_at(1,tweet)
                end
            :retweet->
                tweet=elem(state,1)
                tweet_msg=Map.get(tweet,number,nil)
                if tweet_msg != nil do
                    Enum.map(elem(state,0)|>Map.keys,fn(x)->
                        if GenServer.whereis({x|>Integer.to_string|>String.to_atom,Node.self()}) != nil do
                            GenServer.cast({x|>Integer.to_string|>String.to_atom,Node.self()},{msg,number,tweet_msg})
                        end
                    end)
                end
            :mention->
                mention=elem(state,2)
            :subscribe->
                #we are adding subscribers here for the functions to work
                map=elem(state,0)
                map=Map.put(map,number,1)
                state=Tuple.delete_at(state,0)|>Tuple.insert_at(0,map)
        end        
    {:noreply,state}
    end
end