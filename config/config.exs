use Mix.Config

config :my_tech_hourse, Plants.Repo,
  database: "my_tech_hourse_repo",
  hostname: "localhost",
  username: "postgres",
  password: "4049"


config :my_tech_hourse, ecto_repos: [Plants.Repo]
