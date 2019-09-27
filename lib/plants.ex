defmodule Plants.Plant do
  use Ecto.Schema

  schema "plants" do
    field :flower_name, :string
    field :min_humidity, :integer
    field :max_humidity, :integer
  end

  @doc """
   add plants to the database

    ## Example
     Plants.Plant.add_plant({flower_name, min_humidity, max_humidity})
      where
       flower_name: string
       min_humidity: integer
       max_humidity: integer
  """
  def add_plant({flower_name, min_humidity, max_humidity}) when is_integer(min_humidity) and is_integer(max_humidity) and is_bitstring(flower_name) do
    new_plant = %Plants.Plant{flower_name: flower_name, min_humidity: min_humidity, max_humidity: max_humidity}
    Plants.Repo.insert(new_plant)
  end

  @doc """
   Delete the plant from the database

     ## Example
      Plants.Plant.delete_plant(flower_name)
       where
        flower_name: string
  """
  def delete_plant(flower_name) do
    plant = Plants.Plant |> Plants.Repo.get_by(flower_name: flower_name)
    Plants.Repo.delete(plant)
  end


  @doc """
   Shows all of the plants in the database
  """
  def show_all() do
    Plants.Plant |> Plants.Repo.all
  end

  @doc """
    check if plant is in the database
     ## return value -> boolean
  """
  def is_it_in_db(flower_name) do
    cond do
     Plants.Plant |> Plants.Repo.get_by(flower_name: flower_name) == nil ->
      false
      true ->
        true
    end
  end

  @doc """
    Gets the minimum humidity of the plant
  """
  def get_min_hum(flower_name) do
    %Plants.Plant{flower_name: _, id: _, max_humidity: _max, min_humidity: min} = Plants.Plant |> Plants.Repo.get_by(flower_name: flower_name)
    min
  end


  @doc """
    Gets the maximum humidity of the plant
  """
  def get_max_hum(flower_name) do
    %Plants.Plant{flower_name: _, id: _, max_humidity: max, min_humidity: _min} = Plants.Plant |> Plants.Repo.get_by(flower_name: flower_name)
    max
  end
end


