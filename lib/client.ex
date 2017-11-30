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

    def start_link(args) do
        {:ok, {priv, pub}} = RsaEx.generate_keypair("2048")
        {server,map}=GenServer.call({:global,:Server},{:secret,args|>Atom.to_string|>String.to_integer,pub},:infinity)
        GenServer.start_link(__MODULE__,{map,priv,pub,server},name: {:global,args})
    end

    '''
        0->
        1->
        2->private keys
        3->public keys genserver
        4->server public key
    '''
    def init({args,priv,pub,server}) do
        {:ok,{args,%{},%{},priv,pub,server}} #here the first elem is for the subsriber, #second elem is for the tweets
    end

  def encrypt(msg,public) do
    {:ok, cipher_text} = RsaEx.encrypt(msg, public)
    cipher_text
  end
  
  def decrypt(msg,priv) do
    {:ok, decrypted_clear_text} = RsaEx.decrypt(msg, priv)
    decrypted_clear_text
  end
  
  def handle_call({msg,name},_from,state) do
    reply=""
    pub=elem(state,4)
    priv= elem(state,3)
    case msg do
       :mentions->
         tup=GenServer.call({:global,:Server},{msg,name},:infinity)
         tweet=elem(tup,0)
         mentions=elem(tup,1)
        Enum.map(MapSet.to_list(mentions),fn(x)->
            IO.puts Map.get(tweet,x,"")  
        end)
       :hashtags->
         tup=GenServer.call({:global,:Server},{msg,name,pub},:infinity)
         tweet=elem(tup,0)
         hashtags=elem(tup,1)
         Enum.map(Map.get(hashtags,name,MapSet.new)|>MapSet.to_list,fn(x)->
            IO.puts Map.get(tweet,x,"")   
         end)
    end
    {:reply,reply,state}
  end

    def handle_cast({msg,number,tweet_msg,name},state) do
        priv=elem(state,3)
        pub = elem(state,4)
        server = elem(state,5)
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
                    Enum.map(Map.get(map,:hashtags,[]),fn(x)->
                        GenServer.cast({:global,:Server},{:hashtags_insert,x,number,0})
                    end)
                    Enum.map(Map.get(map,:mentions,[]),fn(x)->
                        if GenServer.whereis({:global,String.replace_prefix(x,"@","")|>String.to_atom}) != nil do
                            GenServer.cast({:global,String.replace_prefix(x,"@","")|>String.to_atom},{:mention,number,tweet_msg,name})
                        end
                        GenServer.cast({:global,:Server},{:mentions,x,number,0})
                    end)
                    GenServer.cast({:global,:Server},{:tweets,number,encrypt(tweet_msg,server),0})
                    GenServer.cast({:global,:Server},{:show,name,encrypt(tweet_msg,server),number})
                    tweet=Map.put(tweet,number,tweet_msg)
                    state=Tuple.delete_at(state,1)|>Tuple.insert_at(1,tweet)
                end
            :retweet->
                tweet=elem(state,1)
                tweet_msg=Map.get(tweet,number,nil)
                if tweet_msg != nil do
                    GenServer.cast({:global,:Server},{:val,0,0,0})
                    IO.puts "RT: from "<>Integer.to_string(name)<>" "<>decrypt(tweet_msg,priv)
                    GenServer.cast({:global,:Server},{:show,name,encrypt(decrypt(tweet_msg,priv),server),number})
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
                tweet=elem(state,1)
                tweet=Map.put(tweet,number,tweet_msg)
                state=Tuple.delete_at(state,1)|>Tuple.insert_at(1,tweet)
        end        
    {:noreply,state}
    end
end