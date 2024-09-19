# nexREPL

An experimental (proof of concept) Elixir
[nREPL](https://nrepl.org/nrepl/index.html) server.

## Demo

See [this tweet](https://twitter.com/mjrusso/status/1836458349463847153).

## Rationale and Motivation

### Why?

Elixir ships with an excellent REPL ([IEx](https://hexdocs.pm/iex/IEx.html)),
which even supports [remote
shells](https://hexdocs.pm/iex/IEx.html#module-remote-shells) out-of-the-box.
However, there's no standard way to evaluate the code you're writing in your
editor directly in the context of an IEx session.

The Clojure community uses [nREPL](https://nrepl.org/nrepl/index.html) to
integrate their editor with their REPL. nREPL doesn't seem to have taken off
outside of the Clojure ecosystem, but the protocol is
[language-agnostic](https://nrepl.org/nrepl/index.html#beyond-clojure), and
there are already [ready-made clients for most
editors](https://nrepl.org/nrepl/usage/clients.html).

If IEx could understand the nREPL protocol, that would theoretically turn all
the red cells to green in the IEx column of [Thomas
Millar](https://github.com/thmsmlr)'s Elixir scripting spreadsheet (see [this
tweet](https://x.com/thmsmlr/status/1814354658858524944)).

### Why Not?

This project validates that an Elixir nREPL server works with existing
(non-Elixir) nREPL clients.

However, to actually make this approach viable for development, nREPL features
like evaluating the expression at the current point need to work. This requires
some understanding of the structure of Elixir code; the core logic for teasing
out the structure could live in the nREPL client exclusively, or alternatively
primarily on the server.

In either case, unfortunately, client modifications will be necessary. Thus,
one of the major benefits of using nREPL in the first place (existing clients
are already written for most editors) is no longer that helpful.

### A Potential Path Forward

What if instead we implemented similar functionality using the LSP, perhaps
piggybacking on a new "eval code" [Code
Action](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_codeAction)
request? With this approach, the client problem is solved, and the LSP server
(which understands code structure) could send the code directly to a networked
IEx shell for evaluation, providing the same benefits as nREPL.

### Additional Discussion

See [this
thread](https://elixirforum.com/t/extending-iex-to-have-nrepl-capabilities/64872)
on Elixir Forum.

## Installation

To install from GitHub, run:

    mix archive.install github mjrusso/nexrepl

To build and install locally, first ensure any previous archive versions are
removed:

    $ mix archive.uninstall nexrepl

And then run:

    $ MIX_ENV=prod mix do archive.build, archive.install

## Usage

First, ensure that your editor has an nREPL client installed and configured
(see [this list](https://nrepl.org/nrepl/usage/clients.html)).

For example, here's what configuration in Emacs could look like (at least for
those of use that use [straight.el](https://github.com/raxod502/straight.el)
with [use-package](https://github.com/jwiegley/use-package)):

``` emacs-lisp
(use-package rail
  :straight (rail :type git :host github :repo "Sasanidas/Rail"))
```

([Rail](https://github.com/Sasanidas/Rail) is a generic nREPL client for Emacs
that does not assume a Clojure server.)

Next, start the nREPL server on the default port (`7888`):

``` shell
iex -S mix nexrepl
```

Then start editing a new or existing Elixir file.

Finally, using the nREPL client you've already configured, start a new nREPL
session, and start evaluating code. (For example, in Emacs with Rail: start a
new session with `M-x rail`, select a region, and then evaluate the region with
`M-x rail-eval-region`.)

## License

nexREPL is released under the terms of the [Apache License 2.0](LICENSE).
Includes vendored code from [Bento](https://github.com/folz/bento); see
[NOTICE](NOTICE) for details.

Copyright (c) 2024, [Michael Russo](https://mjrusso.com).
