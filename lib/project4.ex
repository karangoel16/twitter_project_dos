defmodule Project4 do
  use GenServer
  
  def start_link(args) do
    GenServer.start_link(__MODULE__,args,name: :Server)
  end
  '''
    Here 0->:tweet
         1->:hashtags
         2->:mentions
         3->subscriber of each system
         4->this is for user to tweet id system
  '''
  def init(args) do
    {:ok,{%{},%{},%{},%{},%{}}}
  end

  def main(args) do
    number_of_node=elem(args|>List.to_tuple,0)
    Project4.Exdistutils.start_distributed(:project4)
    Project4.start_link(args)
    number_of_tweets=elem(args|>List.to_tuple,1) #This is for the number of nodes
    IO.puts "Building Network"
    Enum.map(1..String.to_integer(number_of_node),fn(x)->Project4.Client.start_link(Integer.to_string(x)|>String.to_atom)end)
    #IO.puts "Building Subscription list"
    #Enum.map(1..String.to_integer(number_of_node),fn(x)->
    #  GenServer.cast({:Server,Node.self()},{:subscribe,x,Enum.take_random(1..String.to_integer(number_of_node),5)})
    #end)
    IO.puts "Starting Tweet"
    Enum.map(1..String.to_integer(number_of_tweets),fn(x)->
      var=:rand.uniform(String.to_integer(number_of_tweets)+1)
      GenServer.cast({var|>Integer.to_string|>String.to_atom,Node.self()},{:tweet,x,"#"<>RandomBytes.base62<>" "<>"@"<>Integer.to_string(:rand.uniform(String.to_integer(number_of_node))),var})
    end)
    Process.sleep(1_000_000)
  end

  def handle_cast({msg,tweet_id,val},state) do
     case msg do
      :hashtags_insert->
        hash=elem(state,1)
        val1=Map.get(hash,tweet_id)
        if val1==nil do
          val1=MapSet.put(MapSet.new,val)
        else
          val1=MapSet.put(val1,val)
        end
        hash=Map.put(hash,tweet_id,val1)
        state=Tuple.delete_at(state,1)|>Tuple.insert_at(1,hash)
      :tweets->
        tweet=elem(state,0)
        tweet=Map.put(tweet,tweet_id,val)
        #IO.inspect tweet
        state=Tuple.delete_at(state,0)|>Tuple.insert_at(0,tweet)
      :mentions->
        mention=elem(state,2)
        val1=Map.get(mention,tweet_id)
        if val1==nil do
          val1=MapSet.put(MapSet.new,val)
        else
          val1=MapSet.put(val1,val)
        end
        mention=Map.put(mention,tweet_id,val1)
        state=Tuple.delete_at(state,2)|>Tuple.insert_at(2,mention)
      :subscribe->
        subscribe=elem(state,3)
        #val1=Map.get(subscribe,tweet_id,MapSet.new([])) #this will bring out the value of tweets
        val1=MapSet.new(val)
        subscribe=Map.put(subscribe,tweet_id,val1)
        state=Tuple.delete_at(state,3)|>Tuple.insert_at(3,subscribe)
      :user->
        user= elem(state,4)
        user=Map.put(user,val,tweet_id)
        state=Tuple.delete_at(state,4)|>Tuple.insert_at(4,user)
     end
     {:noreply,state}
  end

  def handle_call(msg,_from,state) do
    {:reply,state,state}
  end
end
