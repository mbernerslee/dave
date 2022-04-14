import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :dave, Dave.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "dave_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dave, DaveWeb.Endpoint,
  # url: [host: System.get_env("APP_HOST", "localhost")],
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "UPtr7X1ZQSBvGHXf/3O8nb2rC9rKGV8iEJXlz6Je9oxJAkKxjJ+miSfIGg+prtAU",
  server: false

# In test we don't send emails.
config :dave, Dave.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :debug

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
