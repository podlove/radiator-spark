defmodule Radiator.MixProject do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :radiator,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      package: package(),
      # Docs
      name: "Radiator",
      docs: docs()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Radiator.Application, []},
      extra_applications: [:logger, :runtime_tools, :bamboo, :bamboo_smtp, :inet_cidr]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:hal, "~> 1.1"},
      {:httpoison, "~> 1.5"},
      {:arc, "~> 0.11"},
      {:arc_ecto, github: "podlove/arc_ecto"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      #      {:ecto_autoslug_field, "~> 2.0"},
      #     for ecto 3.2 compatiblity without warnings (switch back to release as soon as they release)
      {:ecto_autoslug_field,
       git: "https://github.com/sobolevn/ecto_autoslug_field.git",
       ref: "49dc8d53919bb80e9e188fcb3aa9dcfb34a8dea3"},
      # for ex_aws
      {:hackney, "~> 1.15"},
      {:sweet_xml, "~> 0.6.5"},
      # for feed import
      {:metalove, "~> 0.3"},
      {:xml_builder, "~> 2.1", override: true},
      {:ex_machina, "~> 2.3", only: :test},
      {:elixir_uuid, "~> 1.2"},
      {:absinthe_plug, "~> 1.4"},
      {:absinthe_phoenix, "~> 1.5.0"},
      {:timex, "~> 3.5"},
      {:cors_plug, "~> 2.0"},
      # audio file metadata extraction and modifying
      {:ffmpex, "~> 0.7.0"},
      # authentication
      {:guardian, "~> 2.0"},
      {:argon2_elixir, "~> 2.0"},
      # mail
      {:bamboo_smtp, "~> 2.0"},
      # for documentation
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev},
      {:chapters, "~> 1.0"},
      {:dataloader, "~> 1.0"},
      {:mime, "~> 1.2"},
      # tracking / analytics
      {:remote_ip, "~> 0.2.0"},
      {:ua_inspector, "~> 2.2.0"},
      # job processor
      {:oban, "~> 0.8"},
      # cron-like job scheduler
      {:quantum, "~> 2.3"},
      # create and use temporary files/directories
      {:temp, "~> 0.4"}
    ]
  end

  defp package do
    [
      maintainers: ["Eric Teubert", "Dominik Wagner"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/podlove/radiator"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: "https://github.com/podlove/radiator",
      logo: "guides/images/podlove-radiator-logo.svg",
      extras: [
        "README.md",
        "guides/data_and_structure.md",
        "guides/rest_api.md",
        "guides/graphql_api.md",
        "guides/Download Tracking.md",
        "guides/Files.md",
        "guides/Users and Permissions.md"
      ]
    ]
  end
end
