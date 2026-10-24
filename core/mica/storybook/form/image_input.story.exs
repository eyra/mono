defmodule Storybook.Frameworks.Pixel.Form.ImageInput do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.image_input/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "No image yet",
        attributes: %{
          label_text: "Banner image",
          image_url: nil,
          uploads: uploads(),
          primary_button_text: "Choose image",
          secondary_button_text: "Replace image"
        }
      },
      %Variation{
        id: :with_image,
        description: "Image uploaded",
        attributes: %{
          label_text: "Banner image",
          image_url: "/images/landing_page/blue-abstract.webp",
          uploads: uploads(),
          primary_button_text: "Choose image",
          secondary_button_text: "Replace image"
        }
      },
      %Variation{
        id: :loading,
        description: "Uploading",
        attributes: %{
          label_text: "Banner image",
          image_url: "/images/landing_page/blue-abstract.webp",
          uploads: uploads(),
          primary_button_text: "Choose image",
          secondary_button_text: "Replace image",
          loading: true
        }
      }
    ]
  end

  defp uploads,
    do: %{
      image: %Phoenix.LiveView.UploadConfig{
        ref: "phx-image-upload",
        name: :image,
        accept: ".png,.jpg,.jpeg"
      }
    }
end
