defmodule Binance.DocsParser do
  defp gen_fx_name(path, method) do
    # find everything in the path after v1/v2/v3
    path_name =
      path
      |> Enum.reverse()
      |> Enum.take_while(fn item ->
        !(String.length(item) == 2 && String.starts_with?(item, "v"))
      end)
      |> Enum.reverse()
      |> Enum.join("_")
      |> Macro.underscore()
      |> String.replace("-", "_")

    method = method |> String.downcase()

    "#{method}_#{path_name}"
    |> String.to_atom()
  end

  defp normalize_entry_item(
         %{
           "name" => name,
           "request" => %{
             "method" => method,
             "url" => %{"path" => path, "query" => query}
           }
         } = args
       ) do
    params = query |> Enum.map(&parse_params/1)

    %{
      method: String.to_atom(method |> String.downcase()),
      name: name,
      query: params,
      path: path,
      needs_auth?: Enum.find(params, nil, &(&1.name == "signature")) != nil,
      unique_key: "#{String.downcase(method)}_#{Enum.join(path, "_")}",
      description: Map.get(args["request"], "description", ""),
      fx_name: gen_fx_name(path, method)
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

  defp normalize_entry(%{"name" => name, "item" => item}) do
    %{
      items:
        item
        |> Enum.map(&normalize_entry_item/1)
        |> List.flatten()
        # remove duplicates
        |> Enum.reduce(%{}, fn item, acc ->
          IO.puts(item.fx_name)
          Map.put(acc, item.fx_name, item)
        end)
        |> Map.values(),
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
    api_path = path |> Enum.join("_") |> String.downcase() |> String.to_atom()

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
