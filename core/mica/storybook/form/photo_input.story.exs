defmodule Storybook.Frameworks.Pixel.Form.PhotoInput do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.photo_input/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "No photo yet",
        attributes: %{
          label_text: "Profile photo",
          photo_url: nil,
          uploads: uploads(),
          primary_button_text: "Choose photo",
          secondary_button_text: "Replace photo"
        }
      },
      %Variation{
        id: :with_photo,
        description: "Photo uploaded",
        attributes: %{
          label_text: "Profile photo",
          photo_url: "/images/landing_page/geel-abstract.svg",
          uploads: uploads(),
          primary_button_text: "Choose photo",
          secondary_button_text: "Replace photo"
        }
      }
    ]
  end

  defp uploads,
    do: %{
      photo: %Phoenix.LiveView.UploadConfig{
        ref: "phx-photo-upload",
        name: :photo,
        accept: ".png,.jpg,.jpeg"
      }
    }
end
