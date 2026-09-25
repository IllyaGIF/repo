# Cydia iOS 3 Repository

Flat APT repository intended for legacy Cydia.

## Layout

- `debs/` — `.deb` packages
- `Packages` — package index
- `Packages.bz2` — bzip2-compressed index for Cydia
- `Packages.gz` — gzip fallback
- `Release` — repository metadata
- `.nojekyll` — prevents GitHub Pages/Jekyll processing
- `index.html` — simple landing page

## Add packages

Copy `.deb` files into `debs/`, then run:

```sh
./scripts/update_repo.sh
```

On macOS, if `dpkg-scanpackages` is missing:

```sh
brew install dpkg
```

Then commit and push all generated repository files.

## GitHub Pages

Publish the repository root from the `main` branch in Settings -> Pages.

A project Pages URL normally has this form:

```text
https://USERNAME.github.io/REPOSITORY/
```

For very old iOS/Cydia, HTTPS/TLS compatibility can be the limiting factor. A custom domain served over plain HTTP can be useful for testing when the device cannot negotiate the TLS configuration used by `github.io`.
