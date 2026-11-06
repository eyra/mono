import Config

config :mica, saas: Next.SaaS

config :mica, assignment_templates: [Next.Systems.Probe.AssignmentTemplate]

config :mica, :account,
  auth_methods: %{
    surfconext: %{provider: true, satellite: true},
    centerdata: %{provider: true, satellite: true},
    google: %{provider: true, satellite: true, mx_provider: "google"},
    email: %{provider: false, satellite: true}
  }

config :mica, :pixel, pool_assets: [:panl, :panl_wide, :panl_dark, :panl_wide_dark]
