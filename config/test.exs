use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :memoet, Memoet.Repo,
  username: "postgres",
  password: "postgres",
  database: "memoet_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  port: System.get_env("DATABASE_PORT") || 5433,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :memoet, MemoetWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
config :memoet, Oban, queues: false, plugins: false
