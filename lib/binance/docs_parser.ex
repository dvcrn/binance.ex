defmodule Binance.DocsParser do
  defp normalize_entry_item(%{
         "name" => name,
         "request" => %{
           "method" => method,
           "url" => %{"path" => path, "query" => query}
         }
       }) do
    params = query |> Enum.map(&parse_params/1)

    %{
      method: String.to_atom(method |> String.downcase()),
      name: name,
      query: params,
      path: path,
      needs_auth?: Enum.find(params, nil, &(&1.name == "signature")) != nil
    }
  end

  # no query version
  defp normalize_entry_item(
         %{
           "name" => name,
           "request" => %{
             "method" => method,
             "url" => %{"path" => path}
           }
         } = rest
       ) do
    Map.put(
      rest,
      "request",
      Map.put(rest["request"], "url", Map.put(rest["request"]["url"], "query", []))
    )
    |> normalize_entry_item()
  end

  defp normalize_entry_item(%{
         "item" => item
       }) do
    item
    |> Enum.map(&normalize_entry_item/1)
  end

  defp normalize_entry(%{"name" => name, "item" => %{"item" => item}}) do
    IO.inspect(item)

    %{
      items: item |> Enum.map(&normalize_entry_item/1) |> List.flatten(),
      group: name
    }
  end

  defp normalize_entry(%{"name" => name, "item" => item}) do
    %{
      items: item |> Enum.map(&normalize_entry_item/1) |> List.flatten(),
      group: name
    }
  end

  def get_documentation do
    File.read!("#{__DIR__}/docs/spot.json")
    |> Poison.decode!()
    |> Map.get("item")
    # don't care about anything besides the items
    |> Enum.map(&normalize_entry/1)
    |> List.flatten()
  end

  def modularize_name(name) do
    Regex.replace(~r/-/, name, "_")
    |> String.replace(" ", "_")
    |> String.replace("(", "")
    |> String.replace(")", "")
    |> String.replace("/", "")
    |> String.capitalize()
    |> String.to_atom()
    |> (&Module.concat(Binance2, &1)).()
  end

  def functionize_name(%{method: method, path: path}) do
    api_path = Enum.take(path, -2) |> Enum.join("_") |> String.downcase() |> String.to_atom()

    "#{String.downcase(Atom.to_string(method))}_#{api_path}"
    |> String.to_atom()
  end

  defp parse_params(%{"key" => key} = args) do
    %{
      name: key,
      description: Map.get(args, "description", ""),
      optional: Map.get(args, "disabled", false)
    }
  end
end
