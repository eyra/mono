defmodule CoreWeb.MultiFormAutoSave do
  defmacro __using__(_opts) do
    quote do
      alias Core.Repo

      # Schedule Save
      @save_delay 1

      defp cancel_save_timer(nil), do: nil
      defp cancel_save_timer(timer), do: Process.cancel_timer(timer)

      def schedule_save(socket, new_changesets) do
        socket =
          update_in(socket.assigns.save_timer, fn timer ->
            cancel_save_timer(timer)
            Process.send_after(self(), :save, @save_delay * 1_000)
          end)

        socket =
          update_in(socket.assigns.changesets, fn existing_changesets ->
            Map.merge(existing_changesets, new_changesets)
          end)

        socket
      end

      # Save
      def save(changeset) do
        if changeset.valid? do
          entity = save_valid(changeset)
          {:ok, entity}
        else
          changeset = %{changeset | action: :save}
          {:error, changeset}
        end
      end

      defp save_valid(changeset) do
        {:ok, entity} = changeset |> Repo.update()
        entity
      end

      # Schedule Hide Message
      @hide_flash_delay 3

      defp cancel_hide_flash_timer(nil), do: nil
      defp cancel_hide_flash_timer(timer), do: Process.cancel_timer(timer)

      def schedule_hide_flash(socket) do
        update_in(socket.assigns.hide_flash_timer, fn timer ->
          cancel_hide_flash_timer(timer)
          Process.send_after(self(), :hide_flash, @hide_flash_delay * 1_000)
        end)
      end

      def hide_flash(socket) do
        cancel_hide_flash_timer(socket.assigns.hide_flash_timer)

        socket
        |> clear_flash()
      end

      def put_error_flash(socket) do
        socket
        |> put_flash(:error, dgettext("eyra-ui", "error.flash"))
      end

      def put_saved_flash(socket) do
        socket
        |> put_flash(:info, dgettext("eyra-ui", "saved.info.flash"))
      end

      # Handle Event

      @impl true
      def handle_event("reset_focus", _, socket) do
        send_update(ToolForm, id: :tool_form, focus: "")
        send_update(PromotionForm, id: :promotion_form, focus: "")
        {:noreply, socket}
      end

      # Handle Info

      @impl true
      def handle_info({:claim_focus, :tool_form}, socket) do
        send_update(PromotionForm, id: :promotion_form, focus: "")
        {:noreply, socket}
      end

      def handle_info({:claim_focus, :promotion_form}, socket) do
        send_update(ToolForm, id: :tool_form, focus: "")
        {:noreply, socket}
      end

      def handle_info({:image_picker, image_id}, socket) do
        send_update(PromotionForm, id: :promotion_form, image_id: image_id)
        {:noreply, socket}
      end

      def handle_info(:save, %{assigns: %{changesets: changesets}} = socket) do
        changesets
        |> Enum.each(fn {_, value} ->
          value |> Repo.update()
        end)

        {
          :noreply,
          socket
          |> assign(changesets: %{})
          |> put_saved_flash()
          |> schedule_hide_flash()
        }
      end

      def handle_info(:hide_flash, socket) do
        {
          :noreply,
          socket
          |> hide_flash()
        }
      end

      def handle_info({:flash, :error}, socket) do
        {
          :noreply,
          socket
          |> put_error_flash()
          |> schedule_hide_flash()
          |> hide_flash()
        }
      end

      def handle_info({:schedule_save, changesets}, socket) do
        {
          :noreply,
          socket
          |> schedule_save(changesets)
        }
      end
    end
  end
end
