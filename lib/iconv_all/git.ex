defmodule IconvAll.Git do
  @moduledoc """
  Convert the contents of a Git repository using iconv.
  """

  alias IconvAll.Git.GitUtils
  alias IconvAll.Git.Iconv

  @type config :: %{
          :repo => Path.t(),
          # Specify the output directory. Must be a non-existent path, otherwise
          # it will throw an error.
          optional(:out_dir) => Path.t(),
          :pattern => String.t(),
          :branch => String.t(),
          :source_encoding => String.t(),
          :target_encoding => String.t(),
          # optional(:force) => bool,
          optional(:discard) => bool,
          optional(:xml_support) => bool
        }

  # `config` with filename.
  @type file_config :: %{
          :filename => Path.t(),
          :repo => Path.t(),
          :pattern => String.t(),
          :branch => String.t(),
          :source_encoding => String.t(),
          :target_encoding => String.t(),
          # optional(:force) => bool,
          optional(:discard) => bool,
          optional(:xml_support) => bool
        }

  @doc """
  Convert the contents of a repository in a separate working tree according to
  `config`.

  ## Examples
  >>> {:ok, worktree} = IconvAll.Git.make_worktree(%{
    repo: "/home/user/git/your_project",
    pattern: "**/*.{xml,csv}",
    branch: "main",
    source_encoding: "shift_jis",
    target_encoding: "utf-8",
    xml_support: true
  })
  """

  @spec make_worktree(config) :: {:ok, Path.t()} | {:error, %{reason: String.t()}}
  def make_worktree(config) when config.source_encoding == config.target_encoding do
    {:error, %{reason: "You can't specify the same value in source_encoding and target_encoding"}}
  end

  def make_worktree(config) do
    # First ensure the source branch points to a valid commit.
    {:ok, source_commit} = GitUtils.rev_parse(config.repo, "refs/heads/#{config.branch}")

    # Determine the path to the created working tree.
    path =
      if is_nil(config.out_dir) do
        Path.join(
          # The working trees are stored in a centralised location.
          cache_dir(),
          Path.basename(config.repo) <>
            make_suffix(
              # A separate working tree should be created whenever the upstream
              # branch is updated or the configuration changes.
              source_commit,
              String.slice(
                Base.encode16(:crypto.hash(:md5, :erlang.term_to_binary(config)), case: :lower),
                0..5
              ),
              # Make the directory name indicate the content encoding for user
              # friendliness.
              config.target_encoding
            )
        )
      else
        if File.exists?(config.out_dir) do
          throw("""
          Directory \"#{config.out_dir}\" which is specified as out_dir of the config already exists
          """)
        else
          config.out_dir
        end
      end

    # Add a fixed prefix allows the user to easily filtering non-production
    # branches. And deduplicating branches hopefully allows garbage collection
    # of Git objects.
    target_branch = "iconv/" <> config.branch

    # In the best scenario, the exact branch and commit is already checked out
    # in a working tree.
    if File.exists?(path) do
      case GitUtils.rev_parse(path, "HEAD~") do
        {:ok, ^source_commit} ->
          # Congratulations! The working tree is already in the expected state,
          # so there is nothing to do.
          {:ok, path}

        _ ->
          # git-switch doesn't remove the working tree of the same branch,
          # so it should be removed.
          GitUtils.remove_worktree_if_exists(config.repo, target_branch)

          # In a bad situation, the previous command could remove the exact
          # working tree. Check if the path still exists.
          if File.exists?(path) do
            with {:ok, _} <-
                   GitUtils.run(path, ["switch", "-C", target_branch, source_commit]),
                 do: iconv_and_git_commit(path, config)
          else
            # This shouldn't happen, but recreate the working tree with the
            # target branch.
            with {:ok, _} <-
                   GitUtils.run(config.repo, [
                     "worktree",
                     "add",
                     "-B",
                     target_branch,
                     path,
                     source_commit
                   ]),
                 do: iconv_and_git_commit(path, config)
          end
      end
    else
      # Remove the previous working tree of the target branch, if any.
      GitUtils.remove_worktree_if_exists(config.repo, target_branch)

      with {:ok, _} <-
             GitUtils.run(config.repo, [
               "worktree",
               "add",
               "-B",
               target_branch,
               path,
               source_commit
             ]),
           do: iconv_and_git_commit(path, config)
    end
  end

  @spec iconv_and_git_commit(Path.t(), config) ::
          {:ok, Path.t()} | {:error, %{reason: String.t()}}
  defp iconv_and_git_commit(path, config) do
    with {:ok, _} <- iconv_batch(path, config),
         {:ok, _} <-
           GitUtils.run(path, [
             "commit",
             # If no file matches the pattern, the operation will be a noop, but
             # allow the commit anyway because it is tedious to tweak the
             # configuration.
             "--allow-empty",
             "-a",
             "-m",
             "Converted files to #{config.target_encoding} using iconv"
           ]),
         # If it succeeds, the second element should be the path to the working
         # tree.
         do: {:ok, path}
  end

  @spec iconv_batch(Path.t(), config) ::
          {:ok, integer()} | {:error, %{reason: String.t()}}
  defp iconv_batch(path, config) do
    for file <- Path.wildcard("#{path}/#{config.pattern}"), reduce: {:ok, nil} do
      {:ok, _} ->
        with {:ok, tmp} <-
               Iconv.convert_file_tmp(
                 file,
                 config.source_encoding,
                 config.target_encoding,
                 discard: Map.get(config, :discard, false)
               ),
             {:ok, newtmp} <-
               postprocess_file(
                 tmp,
                 config
                 |> Map.delete(:out_dir)
                 |> Map.put(:filename, file)
               ),
             do: File.copy(newtmp, file)

      r ->
        r
    end
  end

  @spec postprocess_file(Path.t(), file_config) ::
          {:ok, Path.t()} | {:error, %{reason: String.t()}}
  defp postprocess_file(tmp, config) do
    if Map.has_key?(config, :xml_support) && Map.get(config, :xml_support) &&
         Path.extname(Map.get(config, :filename)) == ".xml" do
      with {:ok, new_tmp} <- Briefly.create(),
           do: IconvAll.Git.Xml.replace_encoding_in_file(tmp, new_tmp, config.target_encoding)
    else
      {:ok, tmp}
    end
  end

  @spec make_suffix(String.t(), String.t(), String.t()) :: String.t()
  defp make_suffix(source_commit, hash, target_encoding) do
    "-#{String.slice(source_commit, 1..7)}-#{hash}.#{target_encoding}"
  end

  @spec cache_dir() :: Path.t()
  defp cache_dir do
    :filename.basedir(:user_cache, "ex_iconv_all_git")
  end
end
