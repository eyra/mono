defmodule Next.Config.DevConfigTest do
  # Sets environment variables while config/dev.exs is evaluated.
  use ExUnit.Case, async: false

  @moduletag :tmp_dir

  @vars ~w(HTTP_PORT OPEN_SENT_EMAILS APP_DOMAIN)

  # Stands in for a developer's own dev.secret.exs, which sets a port and
  # Google redirect of its own.
  @dev_secret """
  import Config

  config :core, CoreWeb.Endpoint, http: [port: 4001]

  config :core, Systems.Account.Auth.Google,
    redirect_uri: "http://localhost:4001/auth/google/callback"
  """

  setup do
    saved = Map.new(@vars, &{&1, System.get_env(&1)})
    Enum.each(@vars, &System.delete_env/1)

    on_exit(fn ->
      Enum.each(saved, fn
        {name, nil} -> System.delete_env(name)
        {name, value} -> System.put_env(name, value)
      end)
    end)
  end

  # Evaluates a copy of config/dev.exs, so the result never depends on the
  # dev.secret.exs of the machine running the test.
  defp dev_config(tmp_dir, env, opts \\ []) do
    File.cp!("config/dev.exs", Path.join(tmp_dir, "dev.exs"))

    if opts[:dev_secret] do
      File.write!(Path.join(tmp_dir, "dev.secret.exs"), @dev_secret)
    end

    System.put_env(env)
    Config.Reader.read!(Path.join(tmp_dir, "dev.exs"), env: :dev)[:core]
  end

  defp port(config), do: config[CoreWeb.Endpoint][:http][:port]
  defp redirect_uri(config), do: config[Systems.Account.Auth.Google][:redirect_uri]
  defp open_url(config), do: config[Systems.Email.Mailer][:open_email_in_browser_url]

  test "without HTTP_PORT, links and sent emails use 4000", %{tmp_dir: tmp_dir} do
    config = dev_config(tmp_dir, %{})

    assert port(config) == nil
    assert redirect_uri(config) == nil
    assert config[:base_url] == "http://localhost:4000"
    assert open_url(config) == "http://localhost:4000/sent_emails"
  end

  test "without HTTP_PORT, dev.secret.exs keeps its port and Google redirect",
       %{tmp_dir: tmp_dir} do
    config = dev_config(tmp_dir, %{}, dev_secret: true)

    assert port(config) == 4001
    assert redirect_uri(config) == "http://localhost:4001/auth/google/callback"
  end

  test "HTTP_PORT wins over dev.secret.exs and moves links and the sent-email viewer",
       %{tmp_dir: tmp_dir} do
    config = dev_config(tmp_dir, %{"HTTP_PORT" => "4035"}, dev_secret: true)

    assert port(config) == 4035
    assert redirect_uri(config) == "http://localhost:4035/auth/google/callback"
    assert config[:base_url] == "http://localhost:4035"
    assert open_url(config) == "http://localhost:4035/sent_emails"
  end

  test "APP_DOMAIN still sets the address used in links", %{tmp_dir: tmp_dir} do
    config =
      dev_config(tmp_dir, %{"HTTP_PORT" => "4035", "APP_DOMAIN" => "https://example.test"})

    assert port(config) == 4035
    assert config[:base_url] == "https://example.test"
  end

  test "OPEN_SENT_EMAILS=false keeps sent emails in the mailbox only", %{tmp_dir: tmp_dir} do
    config = dev_config(tmp_dir, %{"HTTP_PORT" => "4035", "OPEN_SENT_EMAILS" => "false"})

    refute Keyword.has_key?(config[Systems.Email.Mailer], :open_email_in_browser_url)
    assert config[Systems.Email.Mailer][:adapter] == Bamboo.LocalAdapter
  end
end
