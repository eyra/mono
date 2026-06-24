defmodule Systems.Advert.Builders.Highlight do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.{
    Assignment,
    Pool,
    Fund
  }

  defp vm(%Fund.CurrencyModel{} = currency, amount, :reward) do
    reward_title = dgettext("eyra-alliance", "reward.highlight.title")
    locale = Gettext.get_locale(CoreWeb.Gettext)
    reward_text = Fund.CurrencyModel.label(currency, locale, amount || 0)
    %{title: reward_title, text: reward_text}
  end

  def view_model(
        {%Pool.SubmissionModel{pool: %{currency: %Fund.CurrencyModel{} = currency}},
         %Assignment.Model{info: %{subject_reward: amount}}},
        :reward
      ) do
    vm(currency, amount, :reward)
  end

  def view_model(%Fund.RewardModel{amount: amount, fund: %{currency: currency}}, :reward) do
    vm(currency, amount, :reward)
  end

  def view_model(%Assignment.Model{info: info}, :duration) do
    duration = Assignment.InfoModel.duration(info)

    duration_title = dgettext("eyra-alliance", "duration.highlight.title")
    duration_text = dgettext("eyra-alliance", "duration.highlight.text", duration: duration)

    %{title: duration_title, text: duration_text}
  end

  def view_model(%Assignment.Model{} = assignment, :status) do
    status_title = dgettext("eyra-alliance", "status.highlight.title")
    %{title: status_title, text: status_text(assignment)}
  end

  def view_model(%Assignment.Model{} = assignment, :language) do
    language_title = dgettext("eyra-alliance", "language.highlight.title")

    language_text =
      assignment
      |> Assignment.Model.language()
      |> language_text()

    %{title: language_title, text: language_text}
  end

  defp status_text(assignment) do
    cond do
      not Assignment.Public.has_open_spots?(assignment) ->
        dgettext("eyra-alliance", "status.closed.highlight.text")

      not Assignment.Public.has_budget_capacity?(assignment) ->
        dgettext("eyra-alliance", "status.full.highlight.text")

      true ->
        dgettext("eyra-alliance", "status.open.highlight.text")
    end
  end

  defp language_text([]), do: "?"

  defp language_text(languages) when is_list(languages) do
    Enum.map_join(languages, " | ", &translate(&1))
  end

  defp translate(nil), do: "?"

  defp translate(language) do
    Assignment.OnlineStudyLanguages.translate(language)
  end
end
