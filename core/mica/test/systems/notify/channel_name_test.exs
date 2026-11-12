defmodule Systems.Notify.ChannelNameTest do
  use Mica.DataCase, async: false

  alias Mica.Factories
  alias Mica.Repo
  alias Systems.Notify
  alias Systems.Notify.ChannelName
  alias Systems.Notify.MessageModel

  defmodule UnknownChannelNotifier do
    use Systems.Notify.EventDeclaration

    event(:contribution_accepted, channels: [:sms, :email])
  end

  describe "the type" do
    test "casts a known channel atom to the atom" do
      assert ChannelName.cast(:email) == {:ok, :email}
    end

    test "casts a known channel string to the atom" do
      assert ChannelName.cast("na") == {:ok, :na}
    end

    test "casting an unknown channel atom is an error" do
      assert ChannelName.cast(:sms) == :error
    end

    test "casting an unknown channel string is an error" do
      assert ChannelName.cast("sms") == :error
    end

    test "casting a value that is no name is an error" do
      assert ChannelName.cast(1) == :error
    end

    test "dumps a channel atom as its string" do
      assert ChannelName.dump(:email) == {:ok, "email"}
    end

    test "dumps an unknown loaded channel string unchanged" do
      assert ChannelName.dump("sms") == {:ok, "sms"}
    end

    test "loads a known channel as the atom" do
      assert ChannelName.load("email") == {:ok, :email}
    end

    test "loads an unknown channel as the string" do
      assert ChannelName.load("sms") == {:ok, "sms"}
    end
  end

  describe "the message schema" do
    setup do
      user = Factories.insert!(:member)

      {:ok, event} =
        Notify.Public.record_event(%Notify.EventAttrs{
          type: :contribution_accepted,
          subject_user: user,
          metadata: %{"assignment_id" => 42},
          correlation_id: "participation:7"
        })

      %{user: user, event: event}
    end

    test "a known channel round-trips through the database", %{event: event} do
      %{id: id} =
        %MessageModel{}
        |> MessageModel.changeset(%{event_id: event.id, channel: "email"})
        |> Repo.insert!()

      assert %{rows: [["email"]]} =
               Repo.query!("SELECT channel FROM notify_message WHERE id = $1", [id])

      assert Repo.get!(MessageModel, id).channel == :email
    end

    test "casting an unknown channel is a changeset error", %{event: event} do
      changeset = MessageModel.changeset(%MessageModel{}, %{event_id: event.id, channel: :sms})

      refute changeset.valid?
      assert {_, [type: ChannelName, validation: :cast]} = changeset.errors[:channel]
    end

    test "an unknown stored channel loads and makes only its own message fail", %{
      user: user,
      event: event
    } do
      email = Repo.get_by!(MessageModel, event_id: event.id, channel: :email)
      Repo.query!("UPDATE notify_message SET channel = 'sms' WHERE id = $1", [email.id])

      messages = MessageModel |> where(event_id: ^event.id) |> Repo.all()
      assert messages |> Enum.map(& &1.channel) |> Enum.sort() == [:na, "sms"]

      assert Notify.Public.mark_seen(user, correlation_id: "participation:7") == {:ok, 1}

      assert %{status: :failed, failure_reason: ":unknown_channel"} =
               Repo.get!(MessageModel, email.id)

      assert %{status: :seen} = Repo.get_by!(MessageModel, event_id: event.id, channel: :na)
    end
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

  test "every notifier event names a channel of the composition" do
    channels = Mica.SaaS.notify_channels()

    for notifier <- Mica.SaaS.notifiers(), {type, opts} <- notifier.notify_events() do
      for channel <- Keyword.get(opts, :channels, []) do
        assert Map.has_key?(channels, channel),
               "#{inspect(notifier)} routes #{inspect(type)} to unknown channel #{inspect(channel)}"
      end
    end
  end
end
