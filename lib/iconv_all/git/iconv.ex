defmodule IconvAll.Git.Iconv do
  @moduledoc """
  Perform character conversion using the iconv CLI.
  """

  @doc """
  Convert the character encoding of a file using iconv and save the result to
  a temporary file. Return the temporary file as the second item of a tuple.
  """
  @spec convert_file_tmp(Path.t(), String.t(), String.t(), discard: boolean) ::
          {:ok, Path.t()} | {:error, %{reason: String.t()}}
  def convert_file_tmp(file, source_encoding, target_encoding, options) do
    with {:ok, tmp} <- Briefly.create(),
         {:ok, _} <- convert_file(file, tmp, source_encoding, target_encoding, options),
         do: {:ok, tmp}
  end

  @spec convert_file_tmp(Path.t(), String.t(), String.t()) ::
          {:ok, Path.t()} | {:error, %{reason: String.t()}}
  def convert_file_tmp(file, source_encoding, target_encoding),
    do: convert_file_tmp(file, source_encoding, target_encoding, [])

  @spec convert_file(Path.t(), Path.t(), String.t(), String.t(), discard: boolean) ::
          {:ok, nil} | {:error, %{reason: String.t()}}
  defp convert_file(source_file, target_file, source_encoding, target_encoding, options) do
    case System.cmd(
           "iconv",
           if options[:discard] do
             ["-c"]
           else
             []
           end ++
             ["-f", source_encoding, "-t", target_encoding, "-o", target_file, source_file]
         ) do
      {_, 0} ->
        {:ok, nil}

      {out, n} ->
        {:error, %{reason: "iconv failed with exit #{n} on #{source_file}: #{out}"}}
    end
  end
end
