defmodule Next.Account.ParticipantSigninView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Line
  import Systems.Account.UserForm

  alias Systems.Account.User

  @impl true
  def update(%{blocks: blocks, email: email, status: status} = params, socket) do
    add_to_panl = Map.get(params, :add_to_panl, false)

    {
      :ok,
      socket
      |> assign(email: email, blocks: blocks, status: status, add_to_panl: add_to_panl)
      |> update_password_form()
    }
  end

  defp update_password_form(%{assigns: %{email: email, add_to_panl: add_to_panl}} = socket) do
    attrs =
      if User.valid_email?(email) do
        %{"email" => email, "add_to_panl" => to_string(add_to_panl)}
      else
        %{"add_to_panl" => to_string(add_to_panl)}
      end

    assign(socket, :password_form, to_form(attrs))
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <%= for block <- @blocks do %>
          <%= if block == :google do %>
            <.google_signin creator?={false} add_to_panl={@add_to_panl} />
          <% end %>
          <%= if block == :password do %>
            <.password_signin for={@password_form} user_type={:participant} status={@status}/>
          <% end %>
          <%= if block == :seperator do %>
            <.spacing value="M" />
            <.line />
            <.spacing value="M" />
          <% end %>
        <% end %>
      </div>
    """
  end
end
