# nexREPL

An experimental (proof of concept) Elixir
[nREPL](https://nrepl.org/nrepl/index.html) server.

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
