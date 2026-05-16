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

  defp restore(key, nil), do: Application.delete_env(:sprites, key)
  defp restore(key, value), do: Application.put_env(:sprites, key, value)
end
