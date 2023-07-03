# IconvAll.Git

This is an Elixir library that performs encoding conversion using `iconv` on
files in a Git repository. I am trying to analyse some legacy Git repositories
that contains files encoded in legacy non-UTF-8 character sets, which are not
supported by some modern developer tools.

This library performs conversion on files in a Git repository while maintaining
the original directory structure, so it would be especially useful for code
analysis of legacy repositories. A new branch is created from the HEAD commit of
a branch, which will be checked out in a separate working tree.

Also see [kino_iconv_all_git](https://github.com/akirak/kino_iconv_all), which
is a companion to this library.

## Installation

This library is not available on Hex yet.

``` elixir
Mix.install([
  {:iconv_all_git, "~> 0.1.0"}
])
```

or

```elixir
def deps do
  [
    {:iconv_all_git, "~> 0.1.0"}
  ]
end
```
