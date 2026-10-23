defmodule Storybook.Frameworks.Pixel.Button.Dynamic do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.dynamic/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Primary button sending a LiveView event",
        attributes: %{
          action: %{type: :send, event: "save"},
          face: %{type: :primary, label: "Save"}
        }
      },
      %VariationGroup{
        id: :faces,
        description: "Faces (all with a send action)",
        variations: [
          %Variation{
            id: :primary,
            attributes: %{
              action: %{type: :send, event: "publish"},
              face: %{type: :primary, label: "Publish"}
            }
          },
          %Variation{
            id: :primary_icon,
            attributes: %{
              action: %{type: :send, event: "export"},
              face: %{type: :primary, label: "Export", icon: :export}
            }
          },
          %Variation{
            id: :primary_loading,
            attributes: %{
              action: %{type: :send, event: "publish"},
              face: %{type: :primary, label: "Publishing", loading: true}
            }
          },
          %Variation{
            id: :secondary,
            attributes: %{
              action: %{type: :send, event: "decline"},
              face: %{type: :secondary, label: "Decline"}
            }
          },
          %Variation{
            id: :secondary_icon,
            attributes: %{
              action: %{type: :send, event: "create_page"},
              face: %{type: :secondary, label: "Add page", icon: :add}
            }
          },
          %Variation{
            id: :plain,
            attributes: %{
              action: %{type: :send, event: "skip"},
              face: %{type: :plain, label: "Skip for now"}
            }
          },
          %Variation{
            id: :plain_icon,
            attributes: %{
              action: %{type: :send, event: "add"},
              face: %{type: :plain, label: "Add member", icon: :add}
            }
          },
          %Variation{
            id: :label,
            attributes: %{
              action: %{type: :send, event: "cancel"},
              face: %{type: :label, label: "Cancel"}
            }
          },
          %Variation{
            id: :label_icon,
            attributes: %{
              action: %{type: :send, event: "edit_fund"},
              face: %{type: :label, label: "Edit", icon: :edit}
            }
          },
          %Variation{
            id: :icon,
            attributes: %{
              action: %{type: :send, event: "remove"},
              face: %{type: :icon, icon: :remove, alt: "Remove"}
            }
          },
          %Variation{
            id: :link,
            attributes: %{
              action: %{type: :send, event: "show_details"},
              face: %{type: :link, text: "Show details"}
            }
          }
        ]
      },
      %VariationGroup{
        id: :actions,
        description: "Action types",
        variations: [
          %Variation{
            id: :send,
            attributes: %{
              action: %{type: :send, event: "remove", item: "42", target: "#people"},
              face: %{type: :secondary, label: "Remove (send)"}
            }
          },
          %Variation{
            id: :redirect,
            attributes: %{
              action: %{type: :redirect, to: "/project"},
              face: %{type: :primary, label: "Go to projects (redirect)"}
            }
          },
          %Variation{
            id: :http_get,
            attributes: %{
              action: %{type: :http_get, to: "https://example.org", target: "_blank"},
              face: %{type: :plain, label: "Open website (http_get)", icon: :forward}
            }
          },
          %Variation{
            id: :http_post,
            attributes: %{
              action: %{type: :http_post, to: "/auth/transfer/decline"},
              face: %{type: :secondary, label: "Decline (http_post)"}
            }
          },
          %Variation{
            id: :http_download,
            attributes: %{
              action: %{type: :http_download, to: "/images/icons/export.svg"},
              face: %{type: :label, label: "Download (http_download)", icon: :export}
            }
          },
          %Variation{
            id: :submit,
            attributes: %{
              action: %{type: :submit, form_id: "signup_form"},
              face: %{type: :primary, label: "Sign up (submit)"}
            }
          },
          %Variation{
            id: :fake,
            attributes: %{
              action: %{type: :fake},
              face: %{type: :primary, label: "Looks clickable (fake)"}
            }
          }
        ]
      },
      %VariationGroup{
        id: :states,
        description: "Disabled and full width",
        variations: [
          %Variation{
            id: :disabled,
            attributes: %{
              action: %{type: :send, event: "publish"},
              face: %{type: :primary, label: "Publish"},
              enabled?: false
            }
          },
          %Variation{
            id: :disabled_secondary,
            attributes: %{
              action: %{type: :send, event: "decline"},
              face: %{type: :secondary, label: "Decline"},
              enabled?: false
            }
          },
          %Variation{
            id: :full_width,
            attributes: %{
              action: %{type: :send, event: "continue"},
              face: %{type: :primary, label: "Continue"},
              full_width: true
            }
          }
        ]
      }
    ]
  end
end
