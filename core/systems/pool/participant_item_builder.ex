defmodule Systems.Pool.ParticipantItemBuilder do
  use CoreWeb, :verified_routes
  import CoreWeb.Gettext

  def view_model(
        %{
          id: user_id,
          email: email,
          inserted_at: inserted_at,
          profile: %{
            fullname: fullname,
            photo_url: photo_url
          },
          features: features
        },
        _socket
      ) do
    subtitle = email

    tag = get_tag(features)
    photo_url = get_photo_url(photo_url, features)
    image = %{type: :avatar, info: photo_url}

    quick_summery =
      inserted_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    %{
      path: ~p"/pool/participant/#{user_id}",
      title: fullname,
      subtitle: subtitle,
      quick_summary: quick_summery,
      tag: tag,
      image: image
    }
  end

  def get_tag(_) do
    %{type: :success, text: dgettext("link-citizen", "citizen.tag.complete")}
  end

  def get_photo_url(nil, %{gender: :man}), do: "/images/profile_photo_default_male.svg"
  def get_photo_url(nil, %{gender: :woman}), do: "/images/profile_photo_default_female.svg"
  def get_photo_url(nil, _), do: "/images/profile_photo_default.svg"
  def get_photo_url(photo_url, _), do: photo_url
end
