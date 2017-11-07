defmodule Project4.Client do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__,{:ok,args},name: args)
    end

    def init(args) do
        {:ok,{%{},%{}}} #here the first elem is for the subsriber, #second elem is for the tweets
    end
    def handle_call({msg,number,tweet_msg},_from,state) do
        case msg do
            :tweet-> 
                tweet=elem(state,1)
                if Map.get(tweet,number) != nil do
                    tweet=Map.put(tweet,number,tweet_msg)
                    IO.inspect Enum.map(elem(state,0)|>Map.keys,fn(x)->
                        x
                    end)
                end
            :subscribe->
                #we are adding subscribers here for the functions to work
                map=elem(state,0)
                map=Map.put(map,number,1)
                state=Tuple.delete_at(state,0)|>Tuple.insert_at(0,map)
        end        
    {:reply,"",state}
    end
end