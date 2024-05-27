defmodule Systems.Advert.Builders.Highlight do
  import CoreWeb.Gettext

  alias Systems.{
    Assignment,
    Pool,
    Budget
  }

  defp vm(%Budget.CurrencyModel{} = currency, amount, :reward) do
    reward_title = dgettext("eyra-alliance", "reward.highlight.title")
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

  def view_model(%Assignment.Model{info: info}, :duration) do
    duration = Assignment.InfoModel.duration(info)

    duration_title = dgettext("eyra-alliance", "duration.highlight.title")
    duration_text = dgettext("eyra-alliance", "duration.highlight.text", duration: duration)

    %{title: duration_title, text: duration_text}
  end

  def view_model(%Assignment.Model{} = assignment, :status) do
    has_open_spots? = Assignment.Public.has_open_spots?(assignment)
    status_title = dgettext("eyra-alliance", "status.highlight.title")

    status_text =
      if has_open_spots? do
        dgettext("eyra-alliance", "status.open.highlight.text")
      else
        dgettext("eyra-alliance", "status.closed.highlight.text")
      end

    %{title: status_title, text: status_text}
  end

  def view_model(%Assignment.Model{} = assignment, :language) do
    language_title = dgettext("eyra-alliance", "language.highlight.title")

    language_text =
      assignment
      |> Assignment.Model.language()
      |> language_text()

    %{title: language_title, text: language_text}
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
