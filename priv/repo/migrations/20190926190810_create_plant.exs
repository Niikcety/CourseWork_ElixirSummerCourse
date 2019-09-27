defmodule Plants.Repo.Migrations.CreatePlant do
  use Ecto.Migration

  def change do
   create table(:plants) do
    add :flower_name, :string
    add :min_humidity, :integer
    add :max_humidity, :integer
   end
  end
end
