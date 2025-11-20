defmodule Systems.Localization.Resolvers.AssignmentLanguageEnforced do
  @moduledoc """
  Resolves the locale for assignment-related pages:
  - Assignment detail
  - Assignment submission
  - Assignment advert/landing
  """

  alias Systems.Assignment
  alias Systems.Advert

  @default_locale "en"

  @type opts :: [
          {:assignment, any()},
          {:accept_language, String.t() | nil}
        ]

  @spec resolve(map(), opts()) :: String.t()
  def resolve(assigns, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:assignment, assignment_from(assigns))

    locale = resolve_locale(opts)
    CoreWeb.Live.Hook.Locale.put_locale(locale)

    locale
  end

  @spec resolve_locale(opts()) :: String.t()
  def resolve_locale(opts) do
    Keyword.get(opts, :assignment)
    |> assignment_locale()
    |> case do
      nil ->
        @default_locale

      locale ->
        normalize(locale)
    end
  end

  defp assignment_from(%{assignment: assignment}), do: assignment
  defp assignment_from(%{"assignment" => assignment}), do: assignment
  defp assignment_from(_), do: nil

  defp assignment_locale(%Assignment.Model{} = assignment),
    do: Assignment.Model.language(assignment)

  defp assignment_locale(%Assignment.InfoModel{} = info),
    do: Assignment.Model.language(info)

  defp assignment_locale(%Advert.Model{assignment: %Assignment.Model{} = assignment}),
    do: Assignment.Model.language(assignment)

  defp assignment_locale(_), do: nil

  defp normalize(locale) when is_atom(locale), do: locale |> Atom.to_string()
  defp normalize(locale) when is_binary(locale), do: locale
  defp normalize(_), do: @default_locale
end
