defmodule RefrigeratorServer do
  use GenServer

  @moduledoc """
   Refrigerator server that checks if the products are good to eat
  """
  ## Client side
  def start_link() do
   GenServer.start_link(__MODULE__,%{
   door: :closed,
   eggs: %{quantity: 10, expires_in: 200000},
   milk: %{quantity: 5, expires_in: 130000},
   rice: %{quantity: 3, expires_in: 300000},
   meat: %{quantity: 2, expires_in: 230000},
   fish: %{quantity: 7, expires_in: 170000}
   }, name: __MODULE__)
  end

  def init(state) do
    IO.puts "Refrigerator server started"
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    spawn_link(&timer/0)
    schedule_work()
    {:noreply, state}
  end
  def schedule_work() do
    Process.send_after(self(), :work, 5000)
  end

  def stop() do
    GenServer.call(__MODULE__, :stop)
  end

  def terminate(reason) do
    IO.puts "The process was terminated because of #{reason}"
    :ok
  end

  @doc """
   The function opens the refrigerator's door
  """
  def open() do
    GenServer.call(__MODULE__, :open)
  end

  @doc """
   The function closes the refrigerator's door
  """

  def close() do
    GenServer.call(__MODULE__, :close)
  end

  @doc """
   The function prints the products in the refrigerator
  """
  def print() do
    GenServer.call(__MODULE__, :print)
  end

  @doc """
   Add product in the refrigerator

    ## Example
     RefrigeratorServer.add_product({product_name, quantity, expire_in})
      where
       product_name: string
       quantity: integer
       expires_in(in millisecond): integer
  """
  def add_product({product_name,quantity,expire_in}) do
    GenServer.call(__MODULE__,{:add, product_name, quantity, expire_in})
  end

  @doc """
   Removes product in the refrigerator

    ##Example
     RefrigeratorServer.consume_product({product_name, quantity})
      where
       product_name: string
       quantity: integer
  """
  def consume_product({product_name,quantity}) do
    GenServer.call(__MODULE__,{:consume,product_name,quantity})
  end

  ## function that checks the time
  defp timer() do
    GenServer.call(__MODULE__, :time)
  end

  ##Server Side

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_call(:print, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:open, _from, %{door: :closed} = state) do
   {:reply, :opening_door, %{state | door: :opened}}
  end

  def handle_call(:open, _from, %{door: :opened} = state) do
    {:reply, :already_opened, state}
  end

  def handle_call(:close, _from, %{door: :opened} = state) do
    {:reply, :closing_door, %{state | door: :closed}}
  end

  def handle_call(:close, _from, %{door: :closed} = state) do
    {:reply, :already_closed, state}
  end

  def handle_call({:add, product_name, quantity, expire_in},_from, state) do
    cond do
      Map.has_key?(state,product_name) ->
        overal_quantity = state[product_name][:quantity]
        {:reply, :adding_product, Map.put(state,product_name,%{quantity: quantity + overal_quantity, expire_in: expire_in})}
      true->
        {:reply, :adding_product, Map.put_new(state,product_name,%{quantity: quantity, expire_in: expire_in})}
    end
  end

  def handle_call({:consume, product_name, quantity},_from, state) do
    cond do
      Map.has_key?(state,product_name) and state[product_name][:quantity] > quantity ->
        quant = state[product_name][:quantity]
        exp   = state[product_name][:expires_in]
        {:reply, :consuming_product, Map.replace!(state,product_name,%{quantity: quant - quantity, expires_in: exp})}
      Map.has_key?(state,product_name) and state[product_name][:quantity] < quantity ->
        {:reply, :not_enough_quantity, state}
      Map.has_key?(state,product_name) and state[product_name][:quantity] == quantity ->
        product = Atom.to_string(product_name)
        IO.puts "You have ran out of #{product}. Please buy new"
        {:reply, :zero, Map.drop(state, [product_name])}
      true ->
        {:reply, :no_product, state}
    end
  end

  def handle_call(:time, _from, state) do
    new_state = state |> time_remover1()
    {:reply, :time_up, new_state}
  end



  ## Helper functions

  ##updates the state
  defp time_remover1(state) do
    keys = Map.keys(state)
    length = length(keys)
    new_state = %{}
    new_state = Map.put(new_state,:door,state[:door])
    k = time_remover(tl(keys),state,length - 1,new_state)
    k
  end

  ##it checks the expire time and if its greater than zero, takes out 5seconds
  defp time_remover(keys,state,counter,new_state) do
    cond do
      counter == 0 ->
        new_state
      true ->
        %{quantity: quant, expires_in: time} = state[hd(keys)]
        cond do
          time - 5000 <= 0 ->
           product = Atom.to_string(hd(keys))
           IO.puts "The product - #{product} is rotten and it will be removed. Please buy new one"
           time_remover(tl(keys), state, counter - 1 , new_state)
          true ->
           new_state = Map.put(new_state, hd(keys), %{quantity: quant, expires_in: time - 5000})
           time_remover(tl(keys), state, counter - 1 , new_state)
        end
      end
  end

end

