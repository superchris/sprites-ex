defmodule Sprites.CommandTest do
  use ExUnit.Case, async: false

  alias Sprites.Command

  describe "upgrade_timeout/1" do
    setup do
      original = Application.get_env(:sprites, :upgrade_timeout)
      on_exit(fn -> restore(:upgrade_timeout, original) end)
      :ok
    end

    test "defaults to 10_000 when nothing is configured" do
      Application.delete_env(:sprites, :upgrade_timeout)
      assert Command.upgrade_timeout([]) == 10_000
    end

    test "uses application config when set" do
      Application.put_env(:sprites, :upgrade_timeout, 25_000)
      assert Command.upgrade_timeout([]) == 25_000
    end

    test "opts override application config" do
      Application.put_env(:sprites, :upgrade_timeout, 25_000)
      assert Command.upgrade_timeout(upgrade_timeout: 60_000) == 60_000
    end

    test "opts override default" do
      Application.delete_env(:sprites, :upgrade_timeout)
      assert Command.upgrade_timeout(upgrade_timeout: 5_000) == 5_000
    end
  end

  describe "await_session_id/2" do
    test "replies to waiting callers when session_info arrives" do
      reply_ref = make_ref()

      state = %{
        conn: :conn,
        owner: self(),
        ref: make_ref(),
        session_id: nil,
        session_id_waiters: [{self(), reply_ref}]
      }

      json =
        Jason.encode!(%{
          type: "session_info",
          session_id: "1847",
          command: "bash",
          is_owner: true
        })

      assert {:noreply, updated} =
               Command.handle_info({:gun_ws, :conn, :stream, {:text, json}}, state)

      assert_receive {^reply_ref, {:ok, "1847"}}
      assert updated.session_id == "1847"
      assert updated.session_id_waiters == []
    end

    test "returns a session ID that has already arrived" do
      state = %{session_id: "1847", session_id_waiters: []}

      assert {:reply, {:ok, "1847"}, ^state} =
               Command.handle_call(:await_session_id, {self(), make_ref()}, state)
    end
  end

  defp restore(key, nil), do: Application.delete_env(:sprites, key)
  defp restore(key, value), do: Application.put_env(:sprites, key, value)
end
