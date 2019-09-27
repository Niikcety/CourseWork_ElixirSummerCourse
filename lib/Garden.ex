defmodule GardenServer do
  use GenServer
  use Timex

  @moduledoc """
   Garden server that represents two gardens
  """
  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    IO.puts "Garden server started"
    state = %{garden1: %{plants: ["apple","cactus"],humidity: 10 , condition: :bad},
    garden2: %{plants: ["wheat", "hops","apple"], humidity: 70, condition: :very_good},
    sprayer1: :off,
    sprayer2: :off}
    schedule_work()
    schedule_work2()
    schedule_work3()
    {:ok, state}
  end

  def schedule_work() do
    Process.send_after(self(), :work, 60000)
  end
  def schedule_work2() do
    Process.send_after(self(), :work_hard, 180000)
  end

  def schedule_work3() do
    Process.send_after(self(), :work_harder, 600000)
  end

  def handle_info(:work_harder, state) do
    spawn_link(&condition_changer/0)
    schedule_work3()
    {:noreply, state}
  end

  def handle_info(:work_hard, state) do
    spawn_link(&humidity_changer/0)
    schedule_work2()
    {:noreply, state}
  end


  def handle_info(:work, state) do
    spawn_link(&sprayers/0)
    schedule_work()
    {:noreply, state}
   end


  ## turns on the sprayer1
  defp sprayer1_on() do
    GenServer.call(__MODULE__, :sprayer1_on)
  end

  ## turns on the sprayer2
  defp sprayer2_on() do
    GenServer.call(__MODULE__, :sprayer2_on)
  end

  ## turns off the sprayer1
  defp sprayer1_off() do
    GenServer.call(__MODULE__, :sprayer1_off)
  end

  ## turns off the sprayer2
  defp sprayer2_off() do
    GenServer.call(__MODULE__, :sprayer2_off)
  end

  @doc """
    Sows plant in first garden

      ##Example
       GardenServer.sow_garden1(plant_name)
        where
         plant_name: string
  """

  def sow_garden1(plant_name) do
    cond do
      Plants.Plant.is_it_in_db(plant_name) ->
        GenServer.call(__MODULE__, {:sow_garden1, plant_name})
      true ->
        "There is no such plant in the database"
    end
  end

  @doc """
    Sows plant in second garden

     ## Example
       GardenServer.sow_garden2(plant_name)
        where
         plant_name: string
  """
  def sow_garden2(plant_name) do
    cond do
      Plants.Plant.is_it_in_db(plant_name) ->
        GenServer.call(__MODULE__, {:sow_garden2, plant_name})
      true ->
        "There is no such plant in the database"
    end
  end

  ## changes the condition of the garden
  defp condition_changer() do
    cond do
      percentage_of_growing_plants1() > 40 ->
        GenServer.call(__MODULE__, :cond_ch1_down)
      true ->
        GenServer.call(__MODULE__, :cond_ch1_up)
    end
    cond do
      percentage_of_growing_plants2() > 40 ->
        GenServer.call(__MODULE__, :cond_ch2_down)
      true ->
        GenServer.call(__MODULE__, :cond_ch2_up)
    end
  end

  ## changes the humidity of the garden, every three minutes + 1
  defp humidity_changer() do
    GenServer.call(__MODULE__, :humidity_changer)
  end

  def stop() do
    GenServer.call(__MODULE__, :stop)
  end

  def terminate(reason) do
    IO.puts "The server terminated because of #{reason}"
    :ok
  end

  def print() do
    GenServer.call(__MODULE__, :print)
  end

  ## Server side
  def handle_call(:print, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_call(:sprayer1_on, _from, %{sprayer1: :off} = state) do
    {:reply, :sprayer1_on, %{state | sprayer1: :on}}
  end

  def handle_call(:sprayer1_on, _from, %{sprayer1: :on} = state) do
    {:reply, :sprayer1_already_on, state}
  end

  def handle_call(:sprayer2_on, _from, %{sprayer2: :off} = state) do
    {:reply, :sprayer2_on, %{state | sprayer2: :on}}
  end

  def handle_call(:sprayer2_on, _from, %{sprayer2: :on} = state) do
    {:reply, :sprayer2_already_on, state}
  end

  def handle_call(:sprayer1_off, _from, %{sprayer1: :on} = state) do
    {:reply, :sprayer1_off, %{state | sprayer1: :off}}
  end

  def handle_call(:sprayer1_off, _from, %{sprayer1: :off} = state) do
    {:reply, :sprayer1_already_off, state}
  end

  def handle_call(:sprayer2_off, _from, %{sprayer2: :on} = state) do
    {:reply, :sprayer2_off, %{state | sprayer2: :off}}
  end

  def handle_call(:sprayer2_off, _from, %{sprayer2: :off} = state) do
    {:reply, :sprayer2_already_off, state}
  end

  def handle_call({:sow_garden1, plant_name}, _from, state) do
       new_plants = state[:garden1][:plants] ++ [plant_name]
       garden1 = state[:garden1]
       garden1 = %{garden1 | plants: new_plants}
       {:reply, :plant_sew_in_garden1, %{state | garden1: garden1}}
  end

  def handle_call({:sow_garden2, plant_name}, _from, state) do
    new_plants = state[:garden2][:plants] ++ [plant_name]
    garden2 = state[:garden2]
    garden2 = %{garden2 | plants: new_plants}
    {:reply, :plant_sew_in_garden1, %{state | garden2: garden2}}
end

def handle_call(:humidity_changer, _from, state) do
  cond do
    ClimateServer.get_if_its_rainy ->
      {:reply, :humidity_changed,hum_changer(state)}
    are_sprayers_on(state) ->
      {:reply, :humidity_changed,hum_changer(state)}
    true ->
      {:reply, :humidity_changed,hum_changer2(state)}
  end
end

def handle_call(:cond_ch1_down, _from, state) do
  IO.puts "Garden number one is worse"
  {:reply, :garden1_down, condition_changer1_down(state)}
end

def handle_call(:cond_ch1_up, _from, state) do
  IO.puts "Garden number one is better"
  {:reply, :garden1_up, condition_changer1_up(state)}
end

def handle_call(:cond_ch2_down, _from, state) do
  IO.puts "Garden number two is worse"
  {:reply, :garden2_down, condition_changer2_down(state)}
end

def handle_call(:cond_ch2_up, _from, state) do
  IO.puts "Garden number two is better"
  {:reply, :garden2_up, condition_changer2_up(state)}
end

  ## Helper functions

  ## checks if sprayers can be turn on, it is possible between 10am and 7pm
  defp is_it_time_for_sprayers() do
   time = Timex.now("Pacific/Honolulu")
   {{_, _, _},{h, _, _}} = Timex.to_erl(time)
   cond do
    h >= 10 and h <= 19 ->
      false
    true ->
      true
   end
  end

  ## turns on/off the sprayers
  ## on - if its not between 10am and 7 pm
  ## off - if it's rainy or if its between 10am and 7pm
  defp sprayers() do
    cond do
      ClimateServer.get_if_its_rainy() ->
        sprayer1_off()
        sprayer2_off()
      !is_it_time_for_sprayers() ->
        sprayer1_off()
        sprayer2_off()
      true ->
        sprayer1_on()
        sprayer2_on()
    end
  end


  ## Percentage of not growing plants - if more than 40% starting rottening process
  def  percentage_of_growing_plants1() do
   state = print()
   plants = state[:garden1][:plants]
   humidity = state[:garden1][:humidity]
   bad_plants = plants(humidity,plants)
   (bad_plants / length(plants)) * 100
  end

  ## Percentage of not growing plants - if more than 40% starting rottening process
  def percentage_of_growing_plants2() do
    state = print()
    plants = state[:garden2][:plants]
    humidity = state[:garden2][:humidity]
    bad_plants = plants(humidity,plants)
    (bad_plants / length(plants)) * 100
  end


  ## number of plants that are not growing properly
  defp plants(humidity,plants) do
    cond do
      plants == [] ->
        0
      Plants.Plant.get_min_hum(hd(plants)) < humidity and Plants.Plant.get_max_hum(hd(plants)) > humidity ->
        plants(humidity, tl(plants))
      true ->
        1 + plants(humidity,tl(plants))
    end
  end

  ## changes the humidity of the garden
  ## if more than 100 -> humidity = 100
  ## otherwise + 1, every three minutes
  defp hum_changer(state) do
    hum1 = state[:garden1][:humidity]
    hum2 = state[:garden2][:humidity]
    hum1 = if hum1 + 1 > 100, do: 100, else: hum1 + 1
    hum2 = if hum2 + 1 > 100, do: 100, else: hum2 + 1
    garden1 = state[:garden1]
    garden2 = state[:garden2]
    garden1 = %{garden1 | humidity: hum1}
    garden2 = %{garden2 | humidity: hum2}
    state = %{state | garden1: garden1}
    state = %{state | garden2: garden2}
    state
  end

  ## changes the humidity of the garden
  ## if less than 0 -> humidity = 0
  ## otherwise - 1, every three minutes
  defp hum_changer2(state) do
    hum1 = state[:garden1][:humidity]
    hum2 = state[:garden2][:humidity]
    hum1 = if hum1 - 1 < 0, do: 0, else: hum1 - 1
    hum2 = if hum2 - 1 < 0, do: 0, else: hum2 - 1
    garden1 = state[:garden1]
    garden2 = state[:garden2]
    garden1 = %{garden1 | humidity: hum1}
    garden2 = %{garden2 | humidity: hum2}
    state = %{state | garden1: garden1}
    state = %{state | garden2: garden2}
    state
  end

  ## checks if the sprayers are on
  defp are_sprayers_on(state) do
    cond do
    state[:sprayer1] == :on and state[:sprayer2] == :on ->
      true
    true ->
      false
    end
  end

  ## changes the condition for better, garden1
  defp condition_changer1_up(state) do
    conditions = [:very_good, :good, :bad, :very_bad, :rotten]
    condition = state[:garden1][:condition]
    garden1 = state[:garden1]
    index = Enum.find_index(conditions, fn x -> x == condition end)
    garden1 = if index > 0  do
      %{garden1 | condition: Enum.at(conditions, index - 1)}
    else
      garden1
    end
    %{state | garden1: garden1}
  end

  ## changes the condition for better, garden2
  def condition_changer2_up(state) do
    conditions = [:very_good, :good, :bad, :very_bad, :rotten]
    condition = state[:garden2][:condition]
    garden2 = state[:garden2]
    index = Enum.find_index(conditions, fn x -> x == condition end)
    garden2 = if index > 0 do
      %{garden2 | condition: Enum.at(conditions, index - 1)}
    else
      garden2
    end
    %{state | garden2: garden2}
  end

  ## changes the condition for worse, garden1
  def condition_changer1_down(state) do
   conditions = [:very_good, :good, :bad, :very_bad, :rotten]
   condition = state[:garden1][:condition]
   garden1 = state[:garden1]
   index = Enum.find_index(conditions, fn x -> x == condition end)
   garden1 = if index < 4 do
     %{garden1 | condition: Enum.at(conditions, index + 1)}
   else
     garden1
   end
   %{state | garden1: garden1}
  end

  ## changes the condition for worse, garden2
  def condition_changer2_down(state) do
    conditions = [:very_good, :good, :bad, :very_bad, :rotten]
    condition = state[:garden2][:condition]
    garden2 = state[:garden2]
    index = Enum.find_index(conditions, fn x -> x == condition end)
    garden2 = if index < 4 do
      %{garden2 | condition: Enum.at(conditions, index + 1)}
    else
      garden2
    end
    %{state | garden2: garden2}
  end

end
