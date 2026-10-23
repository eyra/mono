defmodule Storybook.Frameworks.Pixel.FileSelector.FileSelector do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.FileSelector.file_selector/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "No file selected yet",
        attributes: %{
          id: "feldspar_tool",
          target: nil,
          label: "Data donation app",
          placeholder: "Select a zip file",
          uploads: uploads([]),
          select_button: "Select file",
          replace_button: "Replace file"
        }
      },
      %Variation{
        id: :selected,
        description: "File already uploaded",
        attributes: %{
          id: "feldspar_tool_selected",
          target: nil,
          label: "Data donation app",
          placeholder: "Select a zip file",
          filename: "port-instagram-v2.zip",
          uploads: uploads([]),
          select_button: "Select file",
          replace_button: "Replace file"
        }
      },
      %Variation{
        id: :uploading,
        description: "Upload in progress",
        attributes: %{
          id: "feldspar_tool_uploading",
          target: nil,
          placeholder: "Select a zip file",
          uploads: uploads([%Phoenix.LiveView.UploadEntry{ref: "0", progress: 40}]),
          select_button: "Select file",
          replace_button: "Replace file"
        }
      }
    ]
  end

  defp uploads(entries) do
    %{
      file: %Phoenix.LiveView.UploadConfig{
        name: :file,
        ref: "phx-file-upload",
        accept: ".zip",
        max_entries: 1,
        entries: entries
      }
    }
  end
end
