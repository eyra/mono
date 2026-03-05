defmodule Fabric.Test do
  use ExUnit.Case, async: true

  import Fabric.Factories

  alias Fabric.LiveComponent.Model
  alias Fabric.LiveComponent.RefModel
  alias Phoenix.LiveView.Socket

  describe "new_fabric/1" do
    test "socket" do
      socket = Fabric.new_fabric(%Socket{})

      assert %Socket{
               assigns: %{
                 __changed__: %{fabric: true},
                 fabric: %Fabric.Model{parent: nil, self: nil, children: nil}
               }
             } = socket
    end
  end

  describe "new_fabric/0" do
    test "default" do
      fabric = Fabric.new_fabric()
      assert %Fabric.Model{parent: nil, self: nil, children: nil} = fabric
    end
  end

  describe "prepare_child/4" do
    test "socket" do
      fabric = %Fabric.Model{parent: nil, children: nil}

      child =
        %Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.prepare_child(:child, Fabric.LiveComponentMock, %{})

      assert %Model{
               ref: %RefModel{
                 id: :child,
                 name: :child,
                 module: Fabric.LiveComponentMock
               },
               params: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: %RefModel{
                     id: :child,
                     module: Fabric.LiveComponentMock
                   },
                   children: nil
                 }
               }
             } = child
    end

    test "fabric" do
      fabric = %Fabric.Model{parent: nil, children: nil}

      child = Fabric.prepare_child(fabric, :child, Fabric.LiveComponentMock, %{})

      assert %Model{
               ref: %RefModel{
                 id: :child,
                 name: :child,
                 module: Fabric.LiveComponentMock
               },
               params: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: %RefModel{
                     id: :child,
                     module: Fabric.LiveComponentMock
                   },
                   children: nil
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
        %Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.get_child(:child)

      assert %Model{
               ref: %RefModel{
                 id: :child,
                 name: :child,
                 module: Fabric.LiveComponentMock
               },
               params: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: %RefModel{
                     id: :child,
                     module: Fabric.LiveComponentMock
                   },
                   children: nil
                 }
               }
             } = child
    end

    test "fabric" do
      child = Fabric.get_child(%Fabric.Model{parent: nil, children: [create_child(:child)]}, :child)

      assert %Model{
               ref: %RefModel{
                 id: :child,
                 name: :child,
                 module: Fabric.LiveComponentMock
               },
               params: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: %RefModel{
                     id: :child,
                     module: Fabric.LiveComponentMock
                   },
                   children: nil
                 }
               }
             } = child
    end
  end

  describe "show_child/2" do
    test "socket" do
      child = create_child(:child)
      fabric = %Fabric.Model{parent: nil, children: nil}

      socket =
        %Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.show_child(child)

      assert %Socket{
               assigns: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: nil,
                   children: [
                     %Model{
                       ref: %RefModel{
                         id: :child,
                         module: Fabric.LiveComponentMock
                       },
                       params: %{
                         fabric: %Fabric.Model{
                           parent: nil,
                           self: %RefModel{
                             id: :child,
                             module: Fabric.LiveComponentMock
                           },
                           children: nil
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

      fabric = Fabric.add_child(%Fabric.Model{parent: nil, children: nil}, child)

      assert %Fabric.Model{
               children: [
                 %Model{
                   ref: %RefModel{
                     id: :child,
                     module: Fabric.LiveComponentMock
                   },
                   params: %{
                     fabric: %Fabric.Model{
                       parent: nil,
                       self: %RefModel{
                         id: :child,
                         module: Fabric.LiveComponentMock
                       },
                       children: nil
                     }
                   }
                 }
               ]
             } = fabric
    end

    test "existing child" do
      child = create_child(:child)

      fabric =
        %Fabric.Model{parent: nil, children: nil}
        |> Fabric.add_child(child)
        |> Fabric.add_child(child)

      assert %Fabric.Model{
               children: [
                 %Model{
                   ref: %RefModel{
                     id: :child,
                     module: Fabric.LiveComponentMock
                   },
                   params: %{
                     fabric: %Fabric.Model{
                       parent: nil,
                       self: %RefModel{
                         id: :child,
                         module: Fabric.LiveComponentMock
                       },
                       children: nil
                     }
                   }
                 }
               ]
             } = fabric
    end
  end

  describe "replace_child/2" do
    test "socket" do
      child_1 = create_child(:child, Fabric.LiveComponentMock, %{some: :thing})
      child_2 = create_child(:child, Fabric.LiveComponentMock, %{another: :thing})

      fabric = %Fabric.Model{parent: nil, children: [child_1]}

      socket =
        %Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.replace_child(child_2)

      assert %Socket{
               assigns: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: nil,
                   children: [
                     %Model{
                       ref: %RefModel{
                         id: :child,
                         module: Fabric.LiveComponentMock
                       },
                       params: %{
                         another: :thing,
                         fabric: %Fabric.Model{
                           parent: nil,
                           self: %RefModel{
                             id: :child,
                             module: Fabric.LiveComponentMock
                           },
                           children: nil
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
      child = create_child(:child, Fabric.LiveComponentMock)

      fabric = %Fabric.Model{parent: nil, children: [child]}

      socket =
        %Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.hide_child(:child)

      assert %Socket{
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
      child = create_child(:child, Fabric.LiveComponentMock)

      fabric = Fabric.remove_child(%Fabric.Model{parent: nil, children: [child]}, :child)

      assert %Fabric.Model{
               parent: nil,
               self: nil,
               children: []
             } = fabric
    end
  end

  describe "show_modal/2" do
    test "socket" do
      socket =
        %Socket{}
        |> Phoenix.Component.assign(:fabric, create_fabric())
        |> Fabric.ModalController.show_modal(create_child(:child), :compact)

      assert_received %{
        fabric_event: %{
          name: "show_modal",
          payload: %Model{
            params: %{
              fabric: %Fabric.Model{
                parent: nil,
                self: %RefModel{
                  id: :child,
                  name: :child,
                  module: Fabric.LiveComponentMock
                },
                children: nil
              }
            },
            ref: %RefModel{
              id: :child,
              name: :child,
              module: Fabric.LiveComponentMock
            }
          }
        }
      }

      self = self()

      assert %Socket{
               assigns: %{
                 fabric: %Fabric.Model{
                   parent: nil,
                   self: %Fabric.LiveView.RefModel{pid: ^self},
                   children: [
                     %Model{
                       ref: %RefModel{
                         id: :child,
                         module: Fabric.LiveComponentMock
                       },
                       params: %{
                         fabric: %Fabric.Model{
                           parent: nil,
                           self: %RefModel{
                             id: :child,
                             module: Fabric.LiveComponentMock
                           },
                           children: nil
                         }
                       }
                     }
                   ]
                 }
               }
             } = socket
    end
  end

  describe "hide_modal/2" do
    test "socket" do
      child = create_child(:child, Fabric.LiveComponentMock)

      fabric = %Fabric.Model{parent: nil, children: [child]}

      socket =
        %Socket{}
        |> Phoenix.Component.assign(:fabric, fabric)
        |> Fabric.ModalController.hide_modal(:child)

      assert_received %{fabric_event: %{name: "hide_modal", payload: %{}}}

      assert %Socket{
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
      socket = Phoenix.Component.assign(%Socket{}, :fabric, create_fabric())

      child = Fabric.prepare_child(socket, :child, Fabric.LiveComponentMock, %{})
      socket = Fabric.show_child(socket, child)

      Fabric.send_event(socket, :child, "event", %{some: :message})

      assert_received {
        :phoenix,
        :send_update,
        {
          {Fabric.LiveComponentMock, :child},
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
      socket = Phoenix.Component.assign(%Socket{}, :fabric, create_fabric())

      child1 = Fabric.prepare_child(socket, :child1, Fabric.LiveComponentMock, %{})
      child2 = Fabric.prepare_child(child1.params.fabric, :child2, Fabric.LiveComponentMock, %{})

      Fabric.send_event(child2.params.fabric, :parent, "event", %{some: :message})

      assert_received {
        :phoenix,
        :send_update,
        {
          {Fabric.LiveComponentMock, :child1},
          %{
            fabric_event: %{
              name: "event",
              payload: %{
                some: :message,
                source: %RefModel{
                  id: :child2,
                  module: Fabric.LiveComponentMock
                }
              }
            },
            id: :child1
          }
        }
      }
    end

    test "child -> root" do
      socket = Phoenix.Component.assign(%Socket{}, :fabric, create_fabric())

      child1 = Fabric.prepare_child(socket, :child1, Fabric.LiveComponentMock, %{})
      child2 = Fabric.prepare_child(child1.params.fabric, :child2, Fabric.LiveComponentMock, %{})

      Fabric.send_event(child2.params.fabric, :root, "event", %{some: :message})

      assert_received %{fabric_event: %{name: "event", payload: %{some: :message}}}
    end

    test "child -> parent (root)" do
      socket = Phoenix.Component.assign(%Socket{}, :fabric, create_fabric())

      child = Fabric.prepare_child(socket, :child, Fabric.LiveComponentMock, %{})

      Fabric.send_event(child.params.fabric, :parent, "event", %{some: :message})

      assert_received %{fabric_event: %{name: "event", payload: %{some: :message}}}
    end
  end
end
