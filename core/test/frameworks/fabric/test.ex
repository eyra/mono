defmodule Fabric.Test do
  use ExUnit.Case, async: true

  import Fabric.Factories

  describe "new_fabric/1" do
    test "socket" do
      socket =
        %Phoenix.LiveView.Socket{}
        |> Fabric.new_fabric()

      assert %Phoenix.LiveView.Socket{
               assigns: %{
                 __changed__: %{fabric: true},
                 fabric: %Fabric.Model{parent: nil, self: nil, children: []}
               }
             } = socket
    end
  end

  describe "new_fabric/0" do
    test "default" do
      fabric = Fabric.new_fabric()
      assert %Fabric.Model{parent: nil, self: nil, children: []} = fabric
    end
  end

  describe "prepare_child/4" do
    test "socket" do
      fabric = %Fabric.Model{parent: nil, children: []}

      child =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.prepare_child(:child, Fabric.TestLiveComponent, %{})

      assert %Fabric.LiveComponent.Model{
               ref: %Fabric.LiveComponent.RefModel{id: :child, module: Fabric.TestLiveComponent},
               params: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: %Fabric.LiveComponent.RefModel{
                     id: :child,
                     module: Fabric.TestLiveComponent
                   },
                   children: []
                 }
               }
             } = child
    end

    test "fabric" do
      fabric = %Fabric.Model{parent: nil, children: []}

      child = Fabric.prepare_child(fabric, :child, Fabric.TestLiveComponent, %{})

      assert %Fabric.LiveComponent.Model{
               ref: %Fabric.LiveComponent.RefModel{id: :child, module: Fabric.TestLiveComponent},
               params: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: %Fabric.LiveComponent.RefModel{
                     id: :child,
                     module: Fabric.TestLiveComponent
                   },
                   children: []
                 }
               }
             } = child
    end
  end

  describe "get_child/2" do
    test "socket" do
      child = create_child(:child)
      fabric = %Fabric.Model{parent: nil, children: [child]}

      child =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.get_child(:child)

      assert %Fabric.LiveComponent.Model{
               ref: %Fabric.LiveComponent.RefModel{id: :child, module: Fabric.TestLiveComponent},
               params: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: %Fabric.LiveComponent.RefModel{
                     id: :child,
                     module: Fabric.TestLiveComponent
                   },
                   children: []
                 }
               }
             } = child
    end

    test "fabric" do
      child =
        %Fabric.Model{parent: nil, children: [create_child(:child)]}
        |> Fabric.get_child(:child)

      assert %Fabric.LiveComponent.Model{
               ref: %Fabric.LiveComponent.RefModel{id: :child, module: Fabric.TestLiveComponent},
               params: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: %Fabric.LiveComponent.RefModel{
                     id: :child,
                     module: Fabric.TestLiveComponent
                   },
                   children: []
                 }
               }
             } = child
    end
  end

  describe "show_child/2" do
    test "socket" do
      child = create_child(:child)
      fabric = %Fabric.Model{parent: nil, children: []}

      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.show_child(child)

      assert %Phoenix.LiveView.Socket{
               assigns: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: nil,
                   children: [
                     %Fabric.LiveComponent.Model{
                       ref: %Fabric.LiveComponent.RefModel{
                         id: :child,
                         module: Fabric.TestLiveComponent
                       },
                       params: %{
                         fabric: %Fabric.Model{
                           parent: nil,
                           self: %Fabric.LiveComponent.RefModel{
                             id: :child,
                             module: Fabric.TestLiveComponent
                           },
                           children: []
                         }
                       }
                     }
                   ]
                 }
               }
             } = socket
    end
  end

  describe "add_child/2" do
    test "socket" do
      child = create_child(:child)
      fabric = %Fabric.Model{parent: nil, children: []}

      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.add_child(child)

      assert %Phoenix.LiveView.Socket{
               assigns: %{
                 fabric: %Fabric.Model{
                   children: [
                     %Fabric.LiveComponent.Model{
                       ref: %Fabric.LiveComponent.RefModel{
                         id: :child,
                         module: Fabric.TestLiveComponent
                       },
                       params: %{
                         fabric: %Fabric.Model{
                           parent: nil,
                           self: %Fabric.LiveComponent.RefModel{
                             id: :child,
                             module: Fabric.TestLiveComponent
                           },
                           children: []
                         }
                       }
                     }
                   ]
                 }
               }
             } = socket
    end
  end

  describe "replace_child/2" do
    test "socket" do
      child_1 = create_child(:child, Fabric.TestLiveComponent, %{some: :thing})
      child_2 = create_child(:child, Fabric.TestLiveComponent, %{another: :thing})

      fabric = %Fabric.Model{parent: nil, children: [child_1]}

      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.replace_child(child_2)

      assert %Phoenix.LiveView.Socket{
               assigns: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: nil,
                   children: [
                     %Fabric.LiveComponent.Model{
                       ref: %Fabric.LiveComponent.RefModel{
                         id: :child,
                         module: Fabric.TestLiveComponent
                       },
                       params: %{
                         another: :thing,
                         fabric: %Fabric.Model{
                           parent: nil,
                           self: %Fabric.LiveComponent.RefModel{
                             id: :child,
                             module: Fabric.TestLiveComponent
                           },
                           children: []
                         }
                       }
                     }
                   ]
                 }
               }
             } = socket
    end
  end

  describe "hide_child/2" do
    test "socket" do
      child = create_child(:child, Fabric.TestLiveComponent)

      fabric = %Fabric.Model{parent: nil, children: [child]}

      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.hide_child(:child)

      assert %Phoenix.LiveView.Socket{
               assigns: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: nil,
                   children: []
                 }
               }
             } = socket
    end
  end

  describe "remove_child/2" do
    test "socket" do
      child = create_child(:child, Fabric.TestLiveComponent)

      fabric = %Fabric.Model{parent: nil, children: [child]}

      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.remove_child(:child)

      assert %Phoenix.LiveView.Socket{
               assigns: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: nil,
                   children: []
                 }
               }
             } = socket
    end
  end

  describe "show_popup/2" do
    test "socket" do
      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, create_fabric())
        |> Fabric.show_popup(create_child(:child))

      assert_received %{
        fabric_event: %{
          name: "show_popup",
          payload: %Fabric.LiveComponent.Model{
            params: %{
              fabric: %Fabric.Model{
                parent: nil,
                self: %Fabric.LiveComponent.RefModel{id: :child, module: Fabric.TestLiveComponent},
                children: []
              }
            },
            ref: %Fabric.LiveComponent.RefModel{id: :child, module: Fabric.TestLiveComponent}
          }
        }
      }

      self = self()

      assert %Phoenix.LiveView.Socket{
               assigns: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: %Fabric.LiveView.RefModel{pid: ^self},
                   children: [
                     %Fabric.LiveComponent.Model{
                       ref: %Fabric.LiveComponent.RefModel{
                         id: :child,
                         module: Fabric.TestLiveComponent
                       },
                       params: %{
                         fabric: %Fabric.Model{
                           parent: nil,
                           self: %Fabric.LiveComponent.RefModel{
                             id: :child,
                             module: Fabric.TestLiveComponent
                           },
                           children: []
                         }
                       }
                     }
                   ]
                 }
               }
             } = socket
    end
  end

  describe "hide_popup/2" do
    test "socket" do
      child = create_child(:child, Fabric.TestLiveComponent)

      fabric = %Fabric.Model{parent: nil, children: [child]}

      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.hide_popup(:child)

      assert_received %{fabric_event: %{name: "hide_popup", payload: %{}}}

      assert %Phoenix.LiveView.Socket{
               assigns: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: nil,
                   children: []
                 }
               }
             } = socket
    end
  end

  describe "send_event/2" do
    test "parent -> child" do
      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, create_fabric())

      child = Fabric.prepare_child(socket, :child, Fabric.TestLiveComponent, %{})
      socket = Fabric.show_child(socket, child)

      Fabric.send_event(socket, :child, "event", %{some: :message})

      assert_received {
        :phoenix,
        :send_update,
        {
          {Fabric.TestLiveComponent, :child},
          %{
            fabric_event: %{
              name: "event",
              payload: %{some: :message}
            },
            id: :child
          }
        }
      }
    end

    test "child -> parent (child)" do
      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, create_fabric())

      child1 = Fabric.prepare_child(socket, :child1, Fabric.TestLiveComponent, %{})
      child2 = Fabric.prepare_child(child1.params.fabric, :child2, Fabric.TestLiveComponent, %{})

      Fabric.send_event(child2.params.fabric, :parent, "event", %{some: :message})

      assert_received {
        :phoenix,
        :send_update,
        {
          {Fabric.TestLiveComponent, :child1},
          %{
            fabric_event: %{
              name: "event",
              payload: %{
                some: :message,
                source: %Fabric.LiveComponent.RefModel{
                  id: :child2,
                  module: Fabric.TestLiveComponent
                }
              }
            },
            id: :child1
          }
        }
      }
    end

    test "child -> root" do
      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, create_fabric())

      child1 = Fabric.prepare_child(socket, :child1, Fabric.TestLiveComponent, %{})
      child2 = Fabric.prepare_child(child1.params.fabric, :child2, Fabric.TestLiveComponent, %{})

      Fabric.send_event(child2.params.fabric, :root, "event", %{some: :message})

      assert_received %{fabric_event: %{name: "event", payload: %{some: :message}}}
    end

    test "child -> parent (root)" do
      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(:fabric, create_fabric())

      child = Fabric.prepare_child(socket, :child, Fabric.TestLiveComponent, %{})

      Fabric.send_event(child.params.fabric, :parent, "event", %{some: :message})

      assert_received %{fabric_event: %{name: "event", payload: %{some: :message}}}
    end
  end
end
