defmodule Sprites.Service do
  @moduledoc """
  Service management for sprites.

  Services are long-running processes managed by the sprite (e.g. background
  workers, web servers). They can be listed, started, and stopped.
  """

  alias Sprites.{Client, Sprite}

  @doc """
  Represents the runtime state of a service.

  ## Fields

    * `:status` - Current status (e.g. "running", "stopped", "starting", "stopping", "failed")
    * `:pid` - OS process id when running, if reported by the API
    * `:exit_code` - Last exit code, if reported
    * `:error` - Last error message, if reported
  """
  defmodule State do
    @type t :: %__MODULE__{
            status: String.t() | nil,
            pid: integer() | nil,
            exit_code: integer() | nil,
            error: String.t() | nil
          }

    defstruct [:status, :pid, :exit_code, :error]

    @doc false
    @spec from_map(map() | nil) :: t() | nil
    def from_map(nil), do: nil

    def from_map(map) when is_map(map) do
      %__MODULE__{
        status: Map.get(map, "status") || Map.get(map, :status),
        pid: Map.get(map, "pid") || Map.get(map, :pid),
        exit_code: Map.get(map, "exit_code") || Map.get(map, :exit_code),
        error: Map.get(map, "error") || Map.get(map, :error)
      }
    end
  end

  @doc """
  Represents a service.

  ## Fields

    * `:name` - Service name (unique within the sprite)
    * `:cmd` - The command line that runs the service
    * `:workdir` - Working directory the service runs in
    * `:state` - Current runtime state (`Sprites.Service.State`)
  """
  @type t :: %__MODULE__{
          name: String.t(),
          cmd: String.t() | nil,
          workdir: String.t() | nil,
          state: State.t() | nil
        }

  defstruct [:name, :cmd, :workdir, :state]

  @doc """
  Creates a service from a map.
  """
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      name: Map.get(map, "name") || Map.get(map, :name),
      cmd: Map.get(map, "cmd") || Map.get(map, :cmd),
      workdir: Map.get(map, "workdir") || Map.get(map, :workdir),
      state: State.from_map(Map.get(map, "state") || Map.get(map, :state))
    }
  end

  @doc """
  Returns true if the service is currently running.
  """
  @spec running?(t()) :: boolean()
  def running?(%__MODULE__{state: %State{status: "running"}}), do: true
  def running?(%__MODULE__{}), do: false

  @doc """
  Lists all services for a sprite.

  ## Examples

      {:ok, services} = Sprites.Service.list(sprite)
  """
  @spec list(Sprite.t()) :: {:ok, [t()]} | {:error, term()}
  def list(%Sprite{client: client, name: name}) do
    list_by_name(client, name)
  end

  @doc """
  Lists all services for a sprite by name.
  """
  @spec list_by_name(Client.t(), String.t()) :: {:ok, [t()]} | {:error, term()}
  def list_by_name(%Client{} = client, name) when is_binary(name) do
    case Req.get(client.req, url: "/v1/sprites/#{URI.encode(name)}/services") do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        services =
          (Map.get(body, "services") || [])
          |> Enum.map(&from_map/1)

        {:ok, services}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Starts a service by name.

  ## Examples

      :ok = Sprites.Service.start(sprite, "web")
  """
  @spec start(Sprite.t(), String.t()) :: :ok | {:error, term()}
  def start(%Sprite{client: client, name: name}, service_name) do
    start_by_name(client, name, service_name)
  end

  @doc """
  Starts a service for a sprite by name.
  """
  @spec start_by_name(Client.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def start_by_name(%Client{} = client, name, service_name)
      when is_binary(name) and is_binary(service_name) do
    url = "/v1/sprites/#{URI.encode(name)}/services/#{URI.encode(service_name)}/start"

    case Req.post(client.req, url: url) do
      {:ok, %{status: status}} when status in 200..299 ->
        :ok

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Stops a service by name.

  ## Examples

      :ok = Sprites.Service.stop(sprite, "web")
  """
  @spec stop(Sprite.t(), String.t()) :: :ok | {:error, term()}
  def stop(%Sprite{client: client, name: name}, service_name) do
    stop_by_name(client, name, service_name)
  end

  @doc """
  Stops a service for a sprite by name.
  """
  @spec stop_by_name(Client.t(), String.t(), String.t()) :: :ok | {:error, term()}
  def stop_by_name(%Client{} = client, name, service_name)
      when is_binary(name) and is_binary(service_name) do
    url = "/v1/sprites/#{URI.encode(name)}/services/#{URI.encode(service_name)}/stop"

    case Req.post(client.req, url: url) do
      {:ok, %{status: status}} when status in 200..299 ->
        :ok

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
