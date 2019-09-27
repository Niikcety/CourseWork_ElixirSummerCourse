defmodule Plants.Repo do
  use Ecto.Repo,
    otp_app: :my_tech_hourse,
    adapter: Ecto.Adapters.Postgres
end
