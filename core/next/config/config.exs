import Config

config :core, saas: Next.SaaS

config :core, assignment_templates: [Systems.Probe.AssignmentTemplate]

config :core, :account,
  auth_methods: %{
    surfconext: %{provider: true, satellite: true},
    centerdata: %{provider: true, satellite: true},
    google: %{provider: true, satellite: true, mx_provider: "google"},
    email: %{provider: false, satellite: true}
  }

config :core, :pixel, pool_assets: [:panl, :panl_wide, :panl_dark, :panl_wide_dark]
