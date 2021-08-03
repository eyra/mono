defmodule Core.Promotions.FormData do
  @moduledoc """
  The study type.
  """
  use Ecto.Schema
  use Timex

  import Ecto.Changeset
  import CoreWeb.Gettext

  alias EyraUI.Timestamp

  alias Core.ImageHelpers

  alias Core.Promotions.Promotion

  alias Core.Enums.Themes
  require Core.Enums.Themes

  embedded_schema do
    # Plain Data
    field(:title, :string)
    field(:subtitle, :string)
    field(:expectations, :string)
    field(:description, :string)
    field(:banner_photo_url, :string)
    field(:banner_title, :string)
    field(:banner_subtitle, :string)
    field(:banner_url, :string)
    # Rich Data (Transient)
    field(:theme_labels, {:array, :any})
    field(:image_url, :string)
    # Support Data (Transient)
    field(:is_published, :boolean)
    field(:byline, :string)
  end

  @required_fields ~w(title subtitle expectations description banner_title banner_subtitle banner_url)a
  @optional_fields ~w(banner_photo_url)a
  @promotion_fields @required_fields ++ @optional_fields

  @transient_fields ~w(is_published theme_labels image_url byline)a
  @fields @promotion_fields ++ @transient_fields

  def changeset(form_data, :publish, params) do
    form_data
    |> cast(params, @fields)
    |> validate_required(@required_fields ++ @transient_fields)
  end

  def changeset(form_data, _, params) do
    form_data
    |> cast(params, @fields)
  end

  def create(promotion) do
    promotion_opts =
      promotion
      |> Map.take(@promotion_fields)

    transient_opts =
      promotion
      |> create_transient_opts()

    opts =
      %{}
      |> Map.merge(promotion_opts)
      |> Map.merge(transient_opts)

    struct(Core.Promotions.FormData, opts)
  end

  defp create_transient_opts(promotion) do
    image_url =
      promotion.image_id
      |> ImageHelpers.get_image_info(400, 300)
      |> Map.get(:url)

    %{}
    |> Map.put(:focus, "")
    |> Map.put(:byline, get_byline(promotion))
    |> Map.put(:is_published, Promotion.published?(promotion))
    |> Map.put(:theme_labels, Themes.labels(promotion.themes))
    |> Map.put(:image_url, image_url)
  end

  defp get_byline(%Promotion{} = promotion) do
    if Promotion.published?(promotion) do
      label = dgettext("eyra-promotion", "published.true.label")
      timestamp = Timestamp.humanize(promotion.published_at)
      "#{label}: #{timestamp}"
    else
      label = dgettext("eyra-promotion", "created.label")
      timestamp = Timestamp.humanize(promotion.inserted_at)
      "#{label}: #{timestamp}"
    end
  end
end
