defmodule Systems.Admin.ActionsViewBuilder do
  @moduledoc """
  ViewBuilder for the Admin ActionsView.

  Builds the view model for administrative actions like:
  - Rolling back expired deposits
  - Marking expired tasks
  - Debug tools (crash button, force expire)
  """
  use Gettext, backend: CoreWeb.Gettext

  @doc """
  Builds the view model for the ActionsView.

  The model parameter is unused but provided for consistency with the ViewBuilder pattern.
  The assigns parameter is unused but available for future use (e.g., feature flags).
  """
  def view_model(_model, _assigns) do
    %{
      title: dgettext("eyra-admin", "actions.title"),
      sections: build_sections(),
      expire_force_button: build_expire_force_button()
    }
  end

  defp build_sections do
    [
      build_bookkeeping_section(),
      build_assignments_section(),
      build_monitoring_section()
    ]
  end

  defp build_bookkeeping_section do
    %{
      title: "Book keeping & Finance",
      buttons: [build_rollback_expired_deposits_button()]
    }
  end

  defp build_assignments_section do
    %{
      title: "Assignments",
      buttons: [build_expire_button()]
    }
  end

  defp build_monitoring_section do
    %{
      title: "Monitoring",
      buttons: [build_crash_button()]
    }
  end

  defp build_rollback_expired_deposits_button do
    %{
      action: %{
        type: :send,
        event: "rollback_expired_deposits"
      },
      face: %{
        type: :primary,
        label: "Rollback expired deposits"
      }
    }
  end

  defp build_expire_button do
    %{
      action: %{
        type: :send,
        event: "expire"
      },
      face: %{
        type: :primary,
        label: "Mark expired tasks"
      }
    }
  end

  defp build_crash_button do
    %{
      action: %{
        type: :send,
        event: "crash"
      },
      face: %{
        type: :primary,
        bg_color: "bg-delete",
        label: "Raise a test exception"
      }
    }
  end

  @doc """
  Builds the expire force button for debug mode.

  This button is only shown when the :debug_expire_force feature flag is enabled.
  Call this separately and include in the view when the flag is enabled.
  """
  def build_expire_force_button do
    %{
      action: %{
        type: :send,
        event: "expire_force"
      },
      face: %{
        type: :primary,
        bg_color: "bg-delete",
        label: "Mark all pending tasks expired"
      }
    }
  end
end
