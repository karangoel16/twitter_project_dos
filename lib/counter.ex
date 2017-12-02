defmodule Project4.Counter do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__,args,name: {:global,:Counter})
    end
    
    #we are maintaining the state of the number 
    def init(args) do
        {:ok,0}
    end

    def handle_call({msg,random},_from,state) do
        {:reply,state,state}
    end

    def handle_cast(msg,state) do
        state=state+1
        {:noreply,state}
    end

    def loop(prev_len) do
        len=GenServer.call({:global,:Counter},{:server,""},:infinity)
        IO.puts len-prev_len
        Process.sleep(1000)
        loop(len)
    end

end