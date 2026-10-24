defmodule Storybook.Systems.Zircon.HTML.RisSelectorForm do
  use PhoenixStorybook.Story, :component

  def function, do: &Systems.Zircon.HTML.ris_selector_form/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Hidden RIS file input with an import button",
        attributes: %{
          uploads: %{file: upload()},
          import_button: %{
            action: %{type: :send, event: "prepare_import"},
            face: %{type: :primary, label: "Import RIS file"}
          }
        }
      }
    ]
  end

  # Same config CoreWeb.FileUploader registers via allow_upload/3 in the import view
  defp upload do
    Phoenix.LiveView.UploadConfig.build(:file, "phx-ris-file",
      accept: ~w(.ris),
      auto_upload: true
    )
  end
end
