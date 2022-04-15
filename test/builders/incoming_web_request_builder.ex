defmodule Dave.IncomingWebRequestBuilder do
  alias Faker.Internet
  alias Dave.{Builder, Constants, IncomingWebRequestIncidentBuilder}

  def build do
    %{path: unique_path(), http_method: Enum.random(Constants.http_methods())}
  end

  defp unique_path_name do
    Internet.slug() <> "-" <> to_string(System.unique_integer([:positive]))
  end

  def with_path(incoming_web_request, path) do
    Map.put(incoming_web_request, :path, path)
  end

  def with_http_method(incoming_web_request, http_method) do
    Map.put(incoming_web_request, :http_method, http_method)
  end

  def with_http_method_get(incoming_web_request) do
    Map.put(incoming_web_request, :http_method, Constants.http_method_get())
  end

  def insert do
    insert(build())
  end

  def insert(incoming_web_request, opts \\ []) do
    returning = Builder.insert(incoming_web_request, "incoming_web_requests", opts)

    id =
      case returning do
        %{id: id} -> id
        id -> id
      end

    if Keyword.get(opts, :insert_incident, true) do
      IncomingWebRequestIncidentBuilder.build()
      |> IncomingWebRequestIncidentBuilder.with_incoming_web_request_id(id)
      |> IncomingWebRequestIncidentBuilder.insert()
    end

    returning
  end

  def unique_path do
    depth = Enum.random(0..4)

    Enum.reduce(1..depth, unique_path_section(), fn _, acc ->
      acc <> unique_path_section()
    end)
  end

  defp unique_path_section do
    "/" <> unique_path_name()
  end
end
