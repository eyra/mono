# iex -S mix dev

Logger.configure(level: :debug)

# Start the catalogue server
Surface.Catalogue.Server.start(
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:catalogue, ~w(--sourcemap=inline --watch)]},
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      System.get_env("NODE_ENV") || "production",
      "--watch-stdin",
      cd: "assets"
    ]
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/.*(ex)$",
      ~r"frameworks/.*(ex)$",
      ~r"systems/.*(ex)$"
    ]
  ]
)
