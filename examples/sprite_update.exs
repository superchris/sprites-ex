# Example: Update Sprite
# Endpoint: PUT /v1/sprites/{name}

token = System.get_env("SPRITE_TOKEN")
sprite_name = System.get_env("SPRITE_NAME")

client = Sprites.new(token)
sprite = Sprites.sprite(client, sprite_name)

:ok = Sprites.update(sprite, url_settings: %{auth: "public"}, labels: ["prod"])

IO.puts("Sprite updated")
