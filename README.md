# Ghostlights theatre

The stage behind [ghostlights.theater](https://ghostlights.theater/): a small static site for *shows*, each made
from one piece of writing, where every claim names its witness (the file it came from, when it was read, a hash
of what was read).

This repository is the theatre, not the repertory. It carries what someone needs to host their own: the stage
(front page, error page, stylesheet), one sample show, the checks the stage keeps, and the deployment files the
live site uses, kept as an example. The shows themselves are written and built elsewhere; the picture book
*So You Want To Build A Ghostwheel?* and the full source of the sample show (its story, its witnesses and the
tool that draws it) live in [inputloop/pubs](https://github.com/inputloop/pubs).

## Layout

- `public/`: the site as served. `index.html` lists the shows; each show is a folder beside it.
- `public/to-the-two-readers/`: the sample show, as built (an animated picture in SVG, with a still for readers
  who ask for less motion, and a page listing each witness).
- `checks/run.sh`: what the stage promises, checked: the CSP (no script, no inline style, nothing from another
  host), every local link resolves, and the front page and the show folders agree. `--prove-red` plants one
  fault per check and requires each to be caught.
- `examples/gw33/`: how ghostlights.theater itself is installed on one nginx host (the TLS site, an interim
  port-80 site, log rotation, and the sentence the site publishes about its request log). `install.sh`
  replaces the live `public/` folder whole (`rsync --delete`), so point it only at a `public/` that holds
  every show you serve.

## Host it

Serve `public/` as plain files with this header, which every page is written to keep:

    Content-Security-Policy: default-src 'none'; style-src 'self'; img-src 'self' data:

Then run `sh checks/run.sh` after every change to `public/`.

## Add a show

Put the built show in `public/NAME/` (an `index.html`, its pictures and its stylesheet, with no script), add a
`<a class="show" href="/NAME/">` entry to `public/index.html`, and run the checks.

## Terms

Scripts: GPL-3.0-or-later OR LGPL-3.0-or-later (`COPYING`, `LICENSES/`). Words and pictures: Copyright 2026
Corwin Brust; CC-BY-SA-4.0 (`LICENSES/CC-BY-SA-4.0.txt`). Made at [inputloop](https://github.com/inputloop).

Mentat (for Corwin, claude-opus-5-5)
