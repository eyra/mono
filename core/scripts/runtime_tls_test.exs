# Build core/Dockerfile, then run: elixir core/scripts/runtime_tls_test.exs IMAGE
ExUnit.start()
ExUnit.configure(timeout: 60_000)

defmodule RuntimeTLSTest do
  use ExUnit.Case
  @image hd(System.argv())

  test "the release runtime loads OS CA roots and verifies HTTPS" do
    # Use the shipped OTP without starting the application or loading its config.
    command = ~S"""
    read -r erts release < /opt/app/releases/start_erl.data
    exec "/opt/app/erts-$erts/bin/erl" -boot "/opt/app/releases/$release/start_clean" \
      -boot_var RELEASE_LIB /opt/app/lib -pa /opt/app/lib/*/ebin -noshell -eval '
      {ok, _} = application:ensure_all_started(inets),
      {ok, _} = application:ensure_all_started(ssl),
      Roots = public_key:cacerts_get(),
      true = length(Roots) > 0,
      Options = [{verify, verify_peer}, {cacerts, Roots},
        {customize_hostname_check,
          [{match_fun, public_key:pkix_verify_hostname_match_fun(https)}]}],
      {ok, {{_, 200, _}, _, _}} = httpc:request(get,
        {"https://example.com/", []},
        [{ssl, Options}, {timeout, 15000}, {connect_timeout, 10000}], []),
      io:format("Verified HTTPS with ~p OS CA roots~n", [length(Roots)]),
      halt(0).'
    """

    {output, status} =
      System.cmd("docker", ["run", "--rm", "--entrypoint", "sh", @image, "-c", command],
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert output =~ "Verified HTTPS with"
  end
end
