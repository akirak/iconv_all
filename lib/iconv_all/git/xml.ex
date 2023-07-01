defmodule IconvAll.Git.Xml do
  @moduledoc """
  A utility module related to XML-specific tasks.
  """

  @doc """
  Replace the encoding attribute of the XML declaration in a file.
  """
  @spec replace_encoding_in_file(Path.t(), Path.t(), String.t()) ::
          {:ok, Path.t()}
  def replace_encoding_in_file(src_file, out_file, target_encoding) do
    File.stream!(src_file)
    # Replacing is performed on only the first occurrence in the first chunk of
    # the stream. In a rare situation, the XML declaration may not be contained
    # in the first chunk, because there is a long whitespace at the beginning of
    # the XML, but I won't take it into account.
    |> Stream.transform(false, fn s, acc ->
      {[
         if acc do
           s
         else
           Regex.replace(
             ~r/\bencoding=(\s*["']?)[-_A-Za-z0-9]+(["']?)\b/,
             s,
             "encoding=\\1#{target_encoding}\\2",
             # Replace only once.
             global: false
           )
         end
       ], true}
    end)
    |> Stream.into(File.stream!(out_file))
    |> Stream.run()

    # The second element of the returned tuple should be the output file anyway,
    # due to how this function is supposed to be integrated.
    # See IconvAll.Git.postprocess_file/2.
    {:ok, out_file}
  end
end
