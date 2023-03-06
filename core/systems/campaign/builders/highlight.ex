defmodule Systems.Campaign.Builders.Highlight do
  import CoreWeb.Gettext

  alias Link.Enums.OnlineStudyLanguages

  alias Systems.{
    Assignment,
    Pool,
    Budget
  }

  defp vm(%Budget.CurrencyModel{} = currency, amount, :reward) do
    reward_title = dgettext("link-survey", "reward.highlight.title")
    locale = Gettext.get_locale(CoreWeb.Gettext)
    reward_text = Budget.CurrencyModel.label(currency, locale, amount)
    %{title: reward_title, text: reward_text}
  end

  def view_model(
        %Pool.SubmissionModel{pool: %{currency: currency}, reward_value: amount},
        :reward
      ) do
    vm(currency, amount, :reward)
  end

  def view_model(%Budget.RewardModel{amount: amount, budget: %{currency: currency}}, :reward) do
    vm(currency, amount, :reward)
  end

  def view_model(%Assignment.Model{assignable_experiment: experiment}, :duration) do
    duration = Assignment.ExperimentModel.duration(experiment)

    duration_title = dgettext("link-survey", "duration.highlight.title")
    duration_text = dgettext("link-survey", "duration.highlight.text", duration: duration)

    %{title: duration_title, text: duration_text}
  end

  def view_model(%Assignment.Model{} = assignment, :status) do
    has_open_spots? = Assignment.Public.has_open_spots?(assignment)
    status_title = dgettext("link-survey", "status.highlight.title")

    status_text =
      if has_open_spots? do
        dgettext("link-survey", "status.open.highlight.text")
      else
        dgettext("link-survey", "status.closed.highlight.text")
      end

    %{title: status_title, text: status_text}
  end

  def view_model(%Assignment.Model{assignable_experiment: experiment}, :language) do
    language_title = dgettext("link-survey", "language.highlight.title")

    language_text =
      Assignment.ExperimentModel.languages(experiment)
      |> language_text()

    %{title: language_title, text: language_text}
  end

  defp language_text([]), do: "?"

  defp language_text(languages) when is_list(languages) do
    Enum.map_join(languages, " | ", &translate(&1))
  end

  defp translate(nil), do: "?"

  defp translate(language) do
    OnlineStudyLanguages.translate(language)
  end
end
