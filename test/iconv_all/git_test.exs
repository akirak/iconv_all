defmodule IconvAll.GitTest do
  use ExUnit.Case, async: false

  alias IconvAll.Git
  alias IconvAll.Git.GitUtils

  @moduletag :tmp_dir

  describe "convert plain text files" do
    setup [:init_tmp]

    test "hello", context do
      IO.inspect(context)
      assert File.dir?(context.origin)
    end
  end

  # test "Convert a normal file"

  # test "Input encodings (:source_encoding option)"

  # test "Output encodings (:target_encoding option)"

  # test "Noop when :source_encoding and :target_encoding are the same"

  # test "Work on a non-head branch with :branch option"

  # test "Specify :pattern option"

  # test "Throw if :repo is not an existing path to directory"
  # test "Throw if :repo is not a Git repository"

  # test "Throw if :pattern is not specified"

  # test "Throw if :branch is not an existing ref"

  # test "Throw if :source_encoding is not supported"

  # test "Throw if :target_encoding is not supported"

  # test ":xml_support option"

  # test ":discard option"

  defp init_tmp(context) do
    tmp_root = context.tmp_dir
    origin = Path.join(tmp_root, "origin")
    out_dir = Path.join(tmp_root, "out")

    case File.mkdir(origin) do
      :ok ->
        GitUtils.run(origin, ["init"])
        {:ok, [origin: origin, out_dir: out_dir]}

      err ->
        err
    end
  end
end
