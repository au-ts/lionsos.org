# LionsOS documentation

This repository holds the source for the documentation website for the Lions Operating System.

If you find any issues with the documentation please file an issue or create
a pull request.

The website is built using the [Hugo static site generator](https://gohugo.io/) with the
[Hugo Book](https://github.com/alex-shpak/hugo-book) theme.

## Dependencies

To install Hugo follow the instructions below for your environment.

On Ubuntu/Debian:
```sh
sudo apt install hugo
```

On macOS with [Homebrew](https://brew.sh/):
```sh
brew install hugo
```

On Nix;
```sh
nix develop
```

## Developing

Each page is written using Markdown and can be found in `content/docs/`.

If you are not familiar with Hugo Book, please see the
[documentation](https://github.com/alex-shpak/hugo-book) and
[example website](https://hugo-book-demo.netlify.app/docs/example/table-of-contents/with-toc/)
to learn more.

If you are developing the documentation and want to preview your changes, run:
```sh
./server.sh
```

You should see a message such as `Web Server is available at http://localhost:1313/`.
Open the link in your browser to view the documentation, the page will automatically
reload on any changes.

## Offline version

If you need store an offline version of the documentation, you should be able to do:
```sh
git clone https://github.com/au-ts/lionsos_docs
cd lionsos_docs
git submodule update --init
hugo --gc --minify
```

All the generated files will be in `public/`.

