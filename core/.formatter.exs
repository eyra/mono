[
  import_deps: [],
  inputs: ["*.{ex,exs}", "{config,bundles,lib,test,frameworks,systems}/**/*.{ex,exs}"],
  subdirectories: [],
  surface_inputs: [
    "{lib,test,bundles,frameworks,systems}/**/*.{ex,exs,sface}",
    "priv/catalogue/**/*.{ex,exs,sface}"
  ]
]
