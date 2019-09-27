defmodule ClimateServer do
  use GenServer

  @moduledoc """
   Server that checks the climate
  """

  ## Client Side
  def start_link() do
    GenServer.start_link(__MODULE__,%{}, name: __MODULE__)
  end

  def init(_) do
    IO.puts "Climate server started"
    [_, _, humidity, _, _] = get_chart()
    state = %{solar_panel: :off,
    moisture_absorber: :off,
    vents: :off,
    humidity: humidity}
    schedule_work()
    {:ok, state}
  end

  def schedule_work() do
    Process.send_after(self(), :work, 60000)
  end

  def handle_info(:work, state) do
    spawn_link(&get_temperature/0)
    spawn_link(&get_if_its_sunny/0)
    spawn_link(&get_humidity/0)
    spawn_link(&get_wind/0)
    schedule_work()
    {:noreply, state}
  end

  @doc """
   Prints the state of the server
  """

  def print() do
    GenServer.call(__MODULE__, :print)
  end

  def stop() do
    GenServer.call(__MODULE__, :stop)
  end

  def terminate(reason) do
    IO.puts("Server terminated because of #{reason}")
    :ok
  end

  ## Server Side


  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end
  def handle_call(:print, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:open_vent, _from, %{:solar_panel => _sp, :moisture_absorber => _ma,vents: :off, humidity: _humidity} = state) do
    {:reply, :opening_vents, %{state | vents: :on}}
  end

  def handle_call(:open_vent, _from, %{:solar_panel => _sp, :moisture_absorber => _ma,vents: :on, humidity: _humidity} = state) do
    {:reply, :already_opened, state}
  end

  def handle_call(:close_vent, _from, %{:solar_panel => _sp, :moisture_absorber => _ma, vents: :off, humidity: _humidity} = state) do
    {:reply, :already_closed, state}
  end

  def handle_call(:close_vent, _from, %{:solar_panel => _sp, :moisture_absorber => _ma,vents: :on, humidity: _humidity} = state) do
    {:reply, :closing_vents, %{state | vents: :off}}
  end

  def handle_call(:solarp_activate, _from, %{:moisture_absorber => _ma, :vents => _v,solar_panel: :off,  humidity: _humidity} = state) do
    {:reply, :activating_solar_panel, %{state | solar_panel: :on}}
  end

  def handle_call(:solarp_activate, _from, %{ :moisture_absorber => _ma,:vents => _v,solar_panel: :on, humidity: _humidity} = state) do
    {:reply, :already_activated, state}
  end

  def handle_call(:solarp_disactivate, _from, %{ :moisture_absorber => _ma,:vents => _v,solar_panel: :off, humidity: _humidity} = state) do
    {:reply, :already_disactivated, state}
  end

  def handle_call(:solarp_disactivate, _from, %{ :moisture_absorber => _ma,:vents => _v,solar_panel: :on, humidity: _humidity} = state) do
    {:reply, :disactivating_solar_panel, %{state | solar_panel: :off}}
  end

  def handle_call(:moistur_activate, _from, %{:solar_panel => _sp,:vents => _v, moisture_absorber: :off, humidity: _humidity} = state) do
    {:reply, :activating_moisture_absorber, %{state | moisture_absorber: :on}}
  end

  def handle_call(:moistur_activate, _from, %{:solar_panel => _sp,:vents => _v, moisture_absorber: :on, humidity: _humidity} = state) do
    {:reply, :already_activated, state}
  end

  def handle_call(:moistur_disactivate, _from, %{:solar_panel => _sp,:vents => _v, moisture_absorber: :off, humidity: _humidity} = state) do
    {:reply, :already_disactivated, state}
  end

  def handle_call(:moistur_disactivate, _from, %{:solar_panel => _sp,:vents => _v, moisture_absorber: :on, humidity: _humidity} = state) do
    {:reply, :disactivating_moisture_absorber, %{state | moisture_absorber: :off}}
  end

  def handle_call(:moistur_minus, _from, %{:solar_panel => _sp, :moisture_absorber => _ma, :vents => _v, humidity: humidity} = state) do
    {:reply, :moistur_minus, %{state | humidity: humidity - 5}}
  end


  ## Helper functions


  ## Gets the temperature and if it's more than 30, it turns the vent on
  defp get_temperature() do

   [temp, _, _, _, _] = get_chart()
   if temp > 30 do
    IO.puts "The vent has been activated"
    GenServer.call(__MODULE__, :open_vent)
   else
    GenServer.call(__MODULE__, :close_vent)
   end
  end

  ## Gets if it's sunny
  defp get_if_its_sunny() do
   [_, clouds, _, _, _] = get_chart()
   if clouds < 11 do
    IO.puts("The solar panel have been activated")
    GenServer.call(__MODULE__, :solarp_activate)
   else
    GenServer.call(__MODULE__, :solarp_disactivate)
   end
  end

  @doc """
   Get if its rainy
  """

  def get_if_its_rainy() do
    chart = url_for_honolulu() |> HTTPoison.get |> parse_response
    list = chart["weather"]
    id = (Enum.at(list,0))["id"]
    cond do
      id >= 200 and id <= 600 ->
        true
      true ->
        false
    end

  end


  ### Shows the humidity
  defp get_humidity() do
   [_, _, humidity, _, _] = get_chart()
   cond do
    humidity >  60 and is_window_open() ->
      GenServer.call(__MODULE__, :moistur_activate)
    humidity > 20 and !is_window_open() ->
      GenServer.call(__MODULE__, :moistur_minus)
    humidity < 20 and !is_window_open() ->
      GenServer.call(__MODULE__, :moistur_disactivate)
   end
  end

  ## Shows the type of wind and it's direction
  defp get_wind() do
    [_, _, _, wind_speed, wind_degree] = get_chart()
    wind_spec = wind_spec(wind_speed)
    wind_dir = wind_direction(wind_degree)
    IO.puts "The wind's type is #{wind_spec} and comes from #{wind_dir}"
  end

  ## Wind type with Beaufort scale
  defp wind_spec(wind_deg) do
   cond do
    wind_deg < 0.5 -> "calm"
    wind_deg >= 0.5 and wind_deg < 1.5 -> "light air"
    wind_deg >= 1.5 and wind_deg < 3.4 -> "light breeze"
    wind_deg >= 3.4 and wind_deg < 5.5 -> "gentle breeze"
    wind_deg >= 5.5 and wind_deg < 7.9 -> "moderate breeze"
    wind_deg >= 7.9 and wind_deg < 10.7 -> "fresh breeze"
    wind_deg >= 10.7 and wind_deg < 13.8 -> "strong breeze"
    wind_deg >= 13.9 and wind_deg < 17.1 -> "high wind"
    wind_deg >= 17.2 and wind_deg < 20.7 -> "gale"
    wind_deg >= 20.8 and wind_deg < 24.4 -> "strong gale"
    wind_deg >= 24.5 and wind_deg < 28.4 -> "storm"
    wind_deg >= 28.5 and wind_deg < 32.6 -> "violent storm"
    true -> "Hurricane force"
   end
  end

  ## Shows the direction of wind
  defp wind_direction(wind_deg) do
   cond do
    wind_deg >= 11.25 and wind_deg < 33.75 -> "north-northeast"
    wind_deg >= 33.75 and wind_deg < 56.25 -> "northeast"
    wind_deg >= 56.25 and wind_deg < 75.75 -> "east-northeast"
    wind_deg >= 75.75 and wind_deg < 101.25 -> "east"
    wind_deg >= 101.25 and wind_deg < 123.75 -> "east-southeast"
    wind_deg >= 123.75 and wind_deg < 146.25 -> "southeast"
    wind_deg >= 146.25 and wind_deg < 168.75 -> "south-southeast"
    wind_deg >= 168.75 and wind_deg < 191.25 -> "south"
    wind_deg >= 191.25 and wind_deg < 213.75 -> "south-southwest"
    wind_deg >= 213.75 and wind_deg < 236.25 -> "southwest"
    wind_deg >= 236.25 and wind_deg < 258.75 -> "west-southwest"
    wind_deg >= 258.75 and wind_deg < 281.25 -> "west"
    wind_deg >= 281.25 and wind_deg < 303.75 -> "west-northwest"
    wind_deg >= 303.75 and wind_deg < 326.25 -> "northwest"
    wind_deg >= 326.25 and wind_deg < 348.75 -> "north-northwest"
    true -> "north"
   end
  end

  ## checks if the window is open
  defp is_window_open() do
    %{:window => state} = AirPollutionServer.print_state()
    case state do
      :opened ->
        true
      _  ->
        false
    end
  end

  ## shows chart requested from weather API
  defp get_chart() do
    chart = url_for_honolulu() |> HTTPoison.get |> parse_response
    temp = chart["main"]["temp"] - 273
    clouds = chart["clouds"]["all"] ## <11
    humidity = chart["main"]["humidity"]
    wind_speed = chart["wind"]["speed"]
    wind_degree = chart["wind"]["deg"]
    [temp,clouds,humidity,wind_speed,wind_degree]

  end

  defp url_for_honolulu() do
    "http://api.openweathermap.org/data/2.5/weather?q=Honolulu,US%20BG&APPID=885ca71f9b213878b5971b016fdbca48"
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
     body |> Jason.decode!
  end


  defp parse_response(_) do
    :error
  end

end
