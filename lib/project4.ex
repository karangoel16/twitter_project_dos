defmodule Project4 do
  use GenServer
  
  @s 1.3

  def start_link(args) do
    GenServer.start_link(__MODULE__,args,name: {:global,:Server})
  end
  '''
    Here 0->:tweet
         1->:hashtags
         2->:mentions
         3->subscriber of each system
         4->this is for user to tweet id
         5->to calculate the number of tweets in the system we will have to save everything
         6->Node id used
  '''
  def init(args) do
    {:ok,{%{},%{},%{},%{},%{},0,0}}
  end

  def cal_const(number_of_nodes) do
    sum=Enum.sum(Enum.map(1..number_of_nodes,fn(x)->:math.pow(1/x,@s) end))
    #IO.puts sum
    1/sum
  end
  
  def main(args) do
    if elem(args|>List.to_tuple,0)=="server" do
      #this is for the number of tweets if we have server in the same
      Project4.Exdistutils.start_distributed(:project4)
      Project4.Counter.start_link(0)
      Project4.start_link(args)
      spawn(fn->Project4.Counter.loop(-1) end)
      Process.sleep(1_000_000_000)
    else
      Project4.Client.connect(args)
      start=elem(GenServer.call({:global,:Server},{:server,""},:infinity),6) #this is to get the starting index of the present node
      number_of_node=elem(args|>List.to_tuple,2)
      GenServer.cast({:global,:Server},{:user_added,number_of_node|>String.to_integer,"",""})
      number_of_tweets=elem(args|>List.to_tuple,3) #This is for the number of nodes 
      IO.puts "Building Network"
      Enum.map(1..String.to_integer(number_of_node),fn(x)->
        Project4.Client.start_link(Integer.to_string(x+start)|>String.to_atom)
      end)
      const_no=cal_const(String.to_integer(number_of_node))
      const=const_no*String.to_integer(number_of_node)
      
      IO.puts "Building Subscription list"
      #we have added start to make the messages go on other nodes as well
      Enum.map(1..String.to_integer(number_of_node),fn(x)->
        spawn(fn->
          val=Enum.take_random(1..(String.to_integer(number_of_node)+start),(const/:math.pow(x,@s)|>:math.ceil|>round))
          GenServer.cast({:global,(x+start)|>Integer.to_string|>String.to_atom},{:subscribe,val,"",""})
          GenServer.cast({:global,:Server},{:subscribe,(x+start),val,0})
        end)
      end)
      if(length(args)>4) do
        Enum.map(1..String.to_integer(elem(args|>List.to_tuple,4)),fn(x)->
          spawn(fn->random_start_stop(x+start)end)
        end)
      end

      IO.puts "Starting Tweet"
      #sub=elem(GenServer.call({:Server,Node.self()},{:server,""}),2)
      const_no=cal_const(String.to_integer(number_of_node))
      const=const_no*String.to_integer(number_of_tweets)
      spawn(fn->
      Enum.reduce(1..String.to_integer(number_of_node),0,fn(x,tweet)->
        Enum.reduce(1..(const/:math.pow(x,@s)|>:math.ceil|>round),tweet,fn(y,tweet)->
          #tweet=Map.keys(elem(GenServer.call({:Server,Node.self()},{:server,""},:infinity),0))|>length
          new_tweet=tweet+1
          if GenServer.whereis({:global,(x+start)|>Integer.to_string|>String.to_atom})!= nil do
            GenServer.cast({:global,(x+start)|>Integer.to_string|>String.to_atom},{:tweet,tweet,"#"<>RandomBytes.base62<>" "<>"@"<>Integer.to_string(:rand.uniform(String.to_integer(number_of_node)+start)),x+start})
            Process.sleep(10)
          end
          new_tweet
        end)
      end)end)
      Process.sleep(1_000_000_000)
    end
  end
  
  
  def random_start_stop(x) do
    Process.sleep(1000)
    if(:rand.uniform(100000)==2) do
      if (GenServer.whereis({:global,x|>Integer.to_string|>String.to_atom})!=nil) do
        GenServer.stop({:global,x|>Integer.to_string|>String.to_atom})
        random_start_stop(x)
      else 
        Project4.Client.start_link(Integer.to_string(x)|>String.to_atom)
        random_start_stop(x)
      end
    else
      random_start_stop(x)
    end
  end
  def handle_cast({msg, tweet_id, val, number },state) do
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
        tweet=Map.get(user,val,MapSet.new)
        tweet=MapSet.put(tweet,tweet_id)
        user=Map.put(user,val,tweet)
        state=Tuple.delete_at(state,4)|>Tuple.insert_at(4,user)
      :val->
        val=elem(state,5)
        val=val+1
        state=Tuple.delete_at(state,5)|>Tuple.insert_at(5,val)
      :show->
        Enum.map(Map.get(elem(state,3),tweet_id,MapSet.new)|>MapSet.to_list,fn(x)->
          if GenServer.whereis({:global,x|>Integer.to_string|>String.to_atom}) != nil do
              GenServer.cast({:global,x|>Integer.to_string|>String.to_atom},{:show, number, val,x})
          else
            GenServer.cast({:global,:Server},{:user,number,x,0})
          end
      end)
      :user_added->
        val=elem(state,6)
        val=val+tweet_id
        state=Tuple.delete_at(state,6)|>Tuple.insert_at(6,val)
     end
     {:noreply,state}
  end

  def handle_call({msg,name},_from,state) do
    reply=""
    case msg do
      :mentions->
        mention=elem(state,2)
        result=Map.get(mention,"@"<>Integer.to_string(name),MapSet.new)
        tweet=elem(state,0)
        reply={tweet,result}
      :server->
        reply=state
      :hashtags->
        hashtags=elem(state,1)
        tweet=elem(state,0)
        reply={tweet,hashtags}
       :user->
        tweet=elem(state,0)
        user=elem(state,4)
        reply={user,tweet}
        user=Map.put(user,name,MapSet.new)
        state=Tuple.delete_at(state,4)|>Tuple.insert_at(4,user)        
    end
    {:reply,reply,state}
  end
end
