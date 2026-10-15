defmodule Systems.Account.FeaturesViewBuilder do
  @moduledoc """
  Builder for FeaturesView that constructs the view model for user features editing.
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Core.Enums.Genders
  alias Frameworks.Pixel.Selector
  alias Systems.Account

  def view_model(%Account.FeaturesModel{} = features, _assigns) do
    gender_labels = Genders.labels(features.gender)
    changeset = Account.FeaturesModel.changeset(features, :auto_save, %{})

    gender_selector =
      LiveNest.Element.prepare_live_component(
        :gender_selector,
        Selector,
        id: :gender_selector,
        items: gender_labels,
        type: :radio
      )

    %{
      title: dgettext("eyra-account", "profile.tab.features.title"),
      description: dgettext("eyra-account", "features.description"),
      gender_title: dgettext("eyra-account", "features.gender.title"),
      birth_year_title: dgettext("eyra-account", "features.birthyear.title"),
      gender_selector: gender_selector,
      changeset: changeset,
      features: features
    }
  end
end
