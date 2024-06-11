defmodule Next.Account.ParticipantSigninView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Line
  import Systems.Account.UserForm

  alias Systems.Account.User

  @impl true
  def update(%{blocks: blocks, email: email}, socket) do
    {
      :ok,
      socket
      |> assign(email: email, blocks: blocks)
      |> update_password_form()
    }
  end

  defp update_password_form(%{assigns: %{email: email}} = socket) do
    attrs =
      if User.valid_email?(email) do
        %{"email" => email}
      else
        %{}
      end

    assign(socket, :password_form, to_form(attrs))
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <%= for block <- @blocks do %>
          <%= if block == :google do %>
            <.google_signin />
          <% end %>
          <%= if block == :password do %>
            <.password_signin for={@password_form} user_type={:participant}/>
          <% end %>
          <%= if block == :seperator do %>
            <.spacing value="S" />
            <.line />
            <.spacing value="M" />
          <% end %>
        <% end %>
      </div>
    """
  end
end
