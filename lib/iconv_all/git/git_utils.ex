defmodule IconvAll.Git.GitUtils do
  @moduledoc """
  Git utilities for `git_iconv` library.
  """

  @doc """
  Get the commit of a reference using git-rev-parse.
  """
  @spec rev_parse(Path.t(), String.t()) ::
          {:ok, String.t()} | {:error, %{reason: String.t()}}
  def rev_parse(repo, commitish) do
    case System.cmd(
           "git",
           ["rev-parse", commitish],
           cd: repo,
           stderr_to_stdout: true
         ) do
      {out, 0} ->
        {:ok, String.trim(out)}

      {out, r} ->
        {:error,
         %{
           reason: "git rev-parse failed with exit code #{r}: #{out}"
         }}
    end
  end

  @doc """
  If there is a working tree that checks out the branch, remove it.
  """
  @spec remove_worktree_if_exists(Path.t(), String.t()) :: :ok
  def remove_worktree_if_exists(repo, branch) do
    worktree_list(repo)
    |> Enum.filter(&(Map.get(&1, "branch", nil) == "refs/heads/#{branch}"))
    |> Enum.each(&run(repo, ["worktree", "remove", "--force", Map.get(&1, "worktree")]))
  end

  @type worktree ::
          %{
            :worktree => Path.t(),
            :HEAD => String.t(),
            :branch => String.t()
          }
          | %{
              :worktree => Path.t(),
              :HEAD => String.t(),
              :DETACHED => true
            }

  @spec worktree_list(Path.t()) :: [worktree]
  defp worktree_list(repo) do
    with {:ok, out} <- run(repo, ["worktree", "list", "--porcelain"]),
         do: parse_worktree_list(out)
  end

  @spec parse_worktree_list(String.t()) :: [worktree]
  defp parse_worktree_list(string) do
    string
    |> String.split("\n")
    |> Enum.chunk_by(&(&1 == ""))
    |> Enum.filter(&(&1 != [""]))
    |> Enum.map(
      &(Enum.map(&1, fn s ->
          case Regex.scan(~r{(worktree|HEAD|branch) (.+)}, s) do
            [[_, key, value]] ->
              {key, value}

            _ ->
              {s, true}
          end
        end)
        |> Enum.into(%{}))
    )
  end

  @doc """
  Run a git command and read its standard output.
  """
  @spec run(Path.t(), [String.t()]) ::
          {:ok, String.t()} | {:error, %{reason: String.t()}}
  def run(repo, args) do
    case System.cmd(
           "git",
           args,
           cd: repo
         ) do
      {out, 0} ->
        {:ok, out}

      {out, r} ->
        {:error, %{reason: "git #{Enum.join(args, " ")} failed with #{r}: #{out}"}}
    end
  end
end
