defmodule Project4 do
  use GenServer
  
  def start_link(args) do
    GenServer.start_link(__MODULE__,args,name: :Server)
  end
  
  def init(args) do
    number_of_nodes=elem(args|>List.to_tuple,0)|>String.to_integer
    {:ok,%{}}
  end
  def main(args) do
    number_of_node=elem(args|>List.to_tuple,0)
    Project4.Exdistutils.start_distributed(:project4)
    IO.inspect Enum.map(1..String.to_integer(number_of_node),fn(x)->spawn(fn->Project4.Client.start_link(Integer.to_string(x)|>String.to_atom) end)end)
    Process.sleep(1_000_000)
  end
end
