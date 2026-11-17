defmodule MicaSaas.Systems.Notify.ChannelNameTest do
  use Mica.DataCase, async: false

  alias Mica.Factories
  alias Mica.Repo
  alias Systems.Notify
  alias Systems.Notify.MessageModel

  defmodule UnknownChannelNotifier do
    use Systems.Notify.EventDeclaration

    event(:contribution_accepted, channels: [:sms, :email])
  end

  describe "dispatch" do
    setup do
      previous = Mica.SaaS.put_composition(notifiers: [UnknownChannelNotifier])
      on_exit(fn -> Mica.SaaS.put_composition(previous) end)
    end

    test "an event routed to an unknown channel still delivers on its known channels" do
      user = Factories.insert!(:member)

      {:ok, event} =
        Notify.Public.record_event(%Notify.EventAttrs{
          type: :contribution_accepted,
          subject_user: user,
          metadata: %{"assignment_id" => 42}
        })

      assert [%{channel: :email, status: :sent}] =
               MessageModel |> where(event_id: ^event.id) |> Repo.all()
    end
  end
end
