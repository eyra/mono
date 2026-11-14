defmodule Systems.Project.NodePageTest do
  use MicaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Mica.Repo
  alias Systems.Project

  setup [:login_as_creator]

  setup %{user: user} do
    {:ok, %{project: project, storage_setup: %{item: item, endpoint: endpoint}}} =
      Project.Assembly.create("Project", user, :empty)

    project = Repo.preload(project, :root)

    %{node: project.root, item: item, endpoint: endpoint}
  end

  test "Data segment links to the storage endpoint", %{conn: conn, node: node, endpoint: endpoint} do
    {:ok, view, _html} = live(conn, ~m"/project/node/#{node.id}")

    assert has_element?(view, ~s(a[href="/storage/endpoint/#{endpoint.id}/content"]), "Data")
  end

  test "without a Data item the Data segment shows the create storage view", %{
    conn: conn,
    node: node,
    item: item
  } do
    Repo.delete!(item)

    {:ok, view, html} = live(conn, ~m"/project/node/#{node.id}")

    refute has_element?(view, ~s(a[href^="/storage/endpoint/"]))
    assert html =~ "Create a storage now."
  end
end
