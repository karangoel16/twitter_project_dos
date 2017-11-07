defmodule Project4.Client do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__,{:ok,args},name: args)
    end

    def init(args) do
        {:ok,%{}}
    end
    def handle_call(msg,_from,state) do
        case msg do
            :tweet-> IO.puts "hi I am here"
        end        
        {:reply,state}
    end
end