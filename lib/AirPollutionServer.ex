defmodule AirPollutionServer do
  use GenServer

  @moduledoc """
    Server that checks if the air is polluted or no
  """

  ## Client side

  def start_link() do
    GenServer.start_link(__MODULE__, %{window: :opened}, name: __MODULE__)
  end

  def init(state) do
    IO.puts "Air pollution server started"
    schedule_work()
    {:ok, state}
  end

  @doc """
    Prints the state of the server
   """

  def print_state() do
    GenServer.call(__MODULE__, :print)
  end

  def handle_info(:work, state) do
    spawn_link(&check_pollution/0)
    schedule_work()
    {:noreply, state}
  end
  def schedule_work() do
    Process.send_after(self(), :work, 60000)
  end


  def stop() do
    GenServer.call(__MODULE__, :stop)
  end

  def terminate(reason) do
    IO.puts("Server terminated because of #{reason}")
    :ok
  end


  defp open() do
    GenServer.call(__MODULE__, :open)
  end

  defp close() do
    GenServer.call(__MODULE__, :close)
  end

  ## Server side
  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_call(:print, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:open, _from, %{window: :opened} = state) do
    {:reply, :already_opened, state}
  end

  def handle_call(:open, _from, %{window: :closed} = state) do
    IO.puts "The window has been opened"
    {:reply, :opening, %{state | window: :opened}}
  end

  def handle_call(:close, _from, %{window: :closed} = state) do
    IO.puts "The window is already closed"
    {:reply, :already_closed, state}
  end

  def handle_call(:close, _from, %{window: :opened} = state) do
    IO.puts "The window has been closed"
    {:reply, :closing, %{state | window: :closed}}
  end

  ## Helper functions

  defp check_pollution() do
    cond do
      get_pm10() >= 50 ->
        close()
      get_pm10() < 50 ->
        open()
    end
  end

  defp get_pm10() do
    pm10 = url_for_honolulu() |> HTTPoison.get |> parse_response
    case pm10 do
      {:ok, temp} ->
        temp
      :error ->
        :error
    end
  end
  defp url_for_honolulu() do
    "https://api.waqi.info/feed/honolulu/?token=59df71901c884e26afed44f0fe33b07fca17e786"
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
     body |> Jason.decode! |> compute_pollution
  end

  defp parse_response(_) do
    :error
  end

  defp compute_pollution(jason) do
    try do
      pm10 = jason["data"]["iaqi"]["pm10"]["v"]
      {:ok, pm10}
    rescue
      _ -> :error
    end
  end

end

