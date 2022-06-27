[
  import_deps: [:surface],
  inputs: [
    "*.{ex,exs}",
    "{config,bundles,lib,test,frameworks,systems}/**/*.{ex,exs}",
    "{lib,test}/**/*.sface"
  ],
  subdirectories: [],
  surface_inputs: [
    "{lib,test,bundles,frameworks,systems}/**/*.{ex,exs,sface}",
    "priv/catalogue/**/*.{ex,exs,sface}"
  ],
  plugins: [Surface.Formatter.Plugin]
]
