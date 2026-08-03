defmodule Sprites.ClientTest do
  use ExUnit.Case, async: true

  alias Sprites.Client

  test "create_sprite forwards metadata and an empty overlay list in the JSON body" do
    Req.Test.stub(__MODULE__, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert Jason.decode!(body) == %{
               "name" => "launchbox",
               "metadata" => %{
                 "repository_url" => "https://github.com/launchscout/launchbox.git",
                 "repository_branch" => "main"
               },
               "overlay_files" => []
             }

      Req.Test.json(conn, %{
        "id" => "sprite-id",
        "name" => "launchbox",
        "status" => "starting"
      })
    end)

    client = Client.new("token", base_url: "https://citrus.test")
    client = %{client | req: Req.merge(client.req, plug: {Req.Test, __MODULE__})}

    assert {:ok, sprite} =
             Client.create_sprite(client, "launchbox",
               metadata: %{
                 "repository_url" => "https://github.com/launchscout/launchbox.git",
                 "repository_branch" => "main"
               },
               overlay_files: []
             )

    assert sprite.id == "sprite-id"
  end
end
