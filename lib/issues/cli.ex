defmodule Issues.CLI do
  @default_count 4
  import Issues.TableFormatter, only: [ print_table_for_columns: 2 ]

  def main(argv) do
    argv |> run
  end

  @moduledoc """
  Handle the command line parsing and the dispatch to the
  various functions that end up generating a table of the
  last _n_ issues in a github project.
  """
  def run(argv) do
    argv
    |> parse_args
    |> process
  end

  @doc """
  `argv` can be -h or --help, which returns :help.

  Otherwise it is a github user name, project name, and
  (optionally) the number of entries to format.

  Return a tuple of `{ user, project, count }`, or `:help`
  if help was given.
  """
  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [ help: :boolean], aliases: [ h: :help ])

    case parse do
    { [ help: true], _, _ } -> :help
    { _, [ user, project, count ], _ } -> { user, project, String.to_integer(count) }
    { _, [ user, project ], _ } -> { user, project, @default_count }
    _ -> :help
    end
  end

  @doc """
  IO.puts usage with :help input

  If tuple of `{user, project, count}` is provided:
  - fetch GitHub API for the issues list
  - sort the issues by created_at ASC
  - take the first count assigned (default to be 4)
  """
  def process(:help) do
    IO.puts """
    usage: issues <user> <project> [ count | #{@default_count} ]
    """
    System.halt(0)
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_response
    |> sort_into_asc_order
    |> Enum.take(count)
    |> print_table_for_columns(["number", "created_at", "title"])
  end

  @doc """
  Extract the API response with elixir object or Print Error if failed to fetch from Github
  """
  def decode_response({:ok, body}), do: body
  def decode_response({:error, error}) do
    {_, message} = Map.fetch(error, "message")
    IO.puts "Error fetching from Github: #{message}"
    System.halt(2)
  end

  @doc """
  Sort the response List ASC by created_at
  """
  def sort_into_asc_order(issues_list) do
    Enum.sort(issues_list, fn i1, i2 -> Map.get(i1, "created_at") <= Map.get(i2, "created_at") end)
  end
end