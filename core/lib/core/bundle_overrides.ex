defmodule Core.BundleOverrides do
  defmacro __using__(_opts \\ []) do
    bundle = Application.fetch_env!(:core, :bundle)
    bundle_info = Mix.Utils.last_modified_and_size("bundles/#{bundle}.ex")

    quote bind_quoted: [bundle: bundle, bundle_info: bundle_info] do
      @bundle bundle
      @bundle_info bundle_info
      def __mix_recompile__? do
        Mix.Utils.last_modified_and_size("bundles/#{Application.fetch_env!(:core, :bundle)}.ex") !=
          @bundle_info
      end
    end
  end

  defmacro grants() do
    call_override(:grants)
  end

  defmacro routes() do
    call_override(:routes)
  end

  defp call_override(override_name) do
    bundle_module = bundle_module()

    if bundle_module && function_exported?(bundle_module, override_name, 0) do
      apply(bundle_module, override_name, [])
    else
      quote do
      end
    end
  end

  defp bundle_module do
    bundle = Application.fetch_env!(:core, :bundle)
    bundle_module_string = bundle |> Atom.to_string() |> String.capitalize()

    "Elixir.#{bundle_module_string}"
    |> String.to_atom()
    |> Code.ensure_compiled()
    |> case do
      {:module, module} -> module
      _ -> nil
    end
  end
end
SPLAYS
