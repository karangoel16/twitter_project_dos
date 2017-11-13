defmodule Project4 do
  use GenServer
  
  @s 2
  @t 1
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

  def cal_const(number_of_nodes) do
    sum=Enum.sum(Enum.map(1..number_of_nodes,fn(x)->:math.pow(1/x,@s) end))
    #IO.puts sum
    1/sum
  end
  def main(args) do
    number_of_node=elem(args|>List.to_tuple,0)
    Project4.Exdistutils.start_distributed(:project4)
    Project4.start_link(args)
    number_of_tweets=elem(args|>List.to_tuple,1) #This is for the number of nodes
    IO.puts "Building Network"
    Enum.map(1..String.to_integer(number_of_node),fn(x)->Project4.Client.start_link(Integer.to_string(x)|>String.to_atom)end)
    GenServer.stop({:"8",Node.self()})
    const_no=cal_const(String.to_integer(number_of_node))
    const=const_no*String.to_integer(number_of_node)
    IO.puts "Building Subscription list"
    Enum.map(1..String.to_integer(number_of_node),fn(x)->
      val=Enum.take_random(1..String.to_integer(number_of_node),(const/:math.pow(x,@s)|>:math.ceil|>round))
      GenServer.cast({x|>Integer.to_string|>String.to_atom,Node.self()},{:subscribe,val,"",""})
      GenServer.cast({:Server,Node.self()},{:subscribe,x,val})
    end)
    IO.puts "Starting Tweet"
    #sub=elem(GenServer.call({:Server,Node.self()},{:server,""}),2)
    const=const_no*String.to_integer(number_of_tweets)
    Enum.map(1..String.to_integer(number_of_node),fn(x)->
      Enum.map(1..(const/:math.pow(x,@s)|>:math.ceil|>round),fn(y)->
        tweet=Map.keys(elem(GenServer.call({:Server,Node.self()},{:server,""},:infinity),0))|>length
        IO.puts tweet
        GenServer.cast({x|>Integer.to_string|>String.to_atom,Node.self()},{:tweet,tweet,"#"<>RandomBytes.base62<>" "<>"@"<>Integer.to_string(:rand.uniform(String.to_integer(number_of_node))),x})
      end)
    end)
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

  def handle_call({msg,name},_from,state) do
    reply=""
    case msg do
      :mentions->
        mention=elem(state,2)
        result=Map.get(mention,"@"<>Integer.to_string(name),%{})
        tweet=elem(state,0)
        reply={tweet,result}
      :server->
        reply=state
      :hashtags->
        hashtags=elem(state,1)
        tweet=elem(state,0)
        reply={tweet,hashtags}
    end
    {:reply,reply,state}
  end
end
