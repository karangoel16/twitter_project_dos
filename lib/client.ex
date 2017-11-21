defmodule Project4.Client do
    use GenServer

    def start_link(args) do
        map=elem(GenServer.call({:Server,Node.self()},{:server,""},:infinity),3)
        GenServer.start_link(__MODULE__,map,name: args)
    end

    def init(args) do
        {:ok,{args,%{},%{}}} #here the first elem is for the subsriber, #second elem is for the tweets
    end

  def handle_call({msg,name},_from,state) do
    reply=""
    case msg do
       :mentions->
         tup=GenServer.call({:Server,Node.self()},{msg,name},:infinity)
         tweet=elem(tup,0)
         mentions=elem(tup,1)
        Enum.map(MapSet.to_list(mentions),fn(x)->
            IO.puts Map.get(tweet,x,"")  
        end)
       :hashtags->
         tup=GenServer.call({:Server,Node.self()},{msg,name},:infinity)
         tweet=elem(tup,0)
         hashtags=elem(tup,1)
         Enum.map(Map.get(hashtags,name,MapSet.new)|>MapSet.to_list,fn(x)->
            IO.puts Map.get(tweet,x,"")   
         end)
    end
    {:reply,reply,state}
  end

    def handle_cast({msg,number,tweet_msg,name},state) do
        case msg do
            :tweet-> 
                #IO.puts tweet_msg
                tweet=elem(state,1)
                if Map.get(tweet,number) == nil do
                    GenServer.cast({:Server,Node.self()},{:val,0,0,0})
                    #this is to increase the value of the tweet in the system
                    #GenServer.cast({:Server,Node.self()},{:user,number,name,0})
                    #this is to add the value of the node in the structure
                    map=SocialParser.extract(tweet_msg,[:hashtags,:mentions])
                    Enum.map(Map.get(map,:hashtags,[]),fn(x)->
                        GenServer.cast({:Server,Node.self()},{:hashtags_insert,x,number,0})
                    end)
                    Enum.map(Map.get(map,:mentions,[]),fn(x)->
                        if GenServer.whereis({String.replace_prefix(x,"@","")|>String.to_atom,Node.self()}) != nil do
                            GenServer.cast({String.replace_prefix(x,"@","")|>String.to_atom,Node.self()},{:mention,number,tweet_msg,name})
                        end
                        GenServer.cast({:Server,Node.self()},{:mentions,x,number,0})
                    end)
                    GenServer.cast({:Server,Node.self()},{:tweets,number,tweet_msg,0})
                    GenServer.cast({:Server,Node.self()},{:show,name,tweet_msg,number})
                    tweet=Map.put(tweet,number,tweet_msg)
                    state=Tuple.delete_at(state,1)|>Tuple.insert_at(1,tweet)
                end
            :retweet->
                tweet=elem(state,1)
                tweet_msg=Map.get(tweet,number,nil)
                if tweet_msg != nil do
                    GenServer.cast({:Server,Node.self()},{:val,0,0,0})
                    #IO.puts tweet_msg
                    GenServer.cast({:Server,Node.self()},{:show,name,tweet_msg,number})
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
                if :rand.uniform(5)==2 do
                    GenServer.cast({name|>Integer.to_string|>String.to_atom,Node.self()},{:retweet,number,tweet_msg,name})
                end
                tweet=elem(state,1)
                tweet=Map.put(tweet,number,tweet_msg)
                state=Tuple.delete_at(state,1)|>Tuple.insert_at(1,tweet)
        end        
    {:noreply,state}
    end
end