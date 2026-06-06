# caddy-brotli

A [Caddy](https://caddyserver.com) v2 encoder module that adds **brotli**
(`br`) response compression.

It registers the `http.encoders.br` module, so it is a drop-in alternative to
[ueffel/caddy-brotli](https://github.com/ueffel/caddy-brotli). Compared to
`ueffel/caddy-brotli`:
- Uses the pure-Go [molecule-man/go-brrr](https://github.com/molecule-man/go-brrr) instead of [andybalholm/brotli](https://github.com/andybalholm/brotli)
- significantly faster compression
- lower CPU usage


## Build

Use [xcaddy](https://github.com/caddyserver/xcaddy):

```sh
xcaddy build --with github.com/fuckoffel/caddy-brotli
```

Because `http.encoders.br` can only be registered once, do **not** combine this
with `ueffel/caddy-brotli` in the same build.

## Usage

Brotli is added as a `br` encoding inside Caddy's `encode` directive.

```caddyfile
# Defaults (level 4, go-brrr's default window).
encode br

# Alongside gzip; clients negotiate via Accept-Encoding.
encode gzip br

# Explicit compression level (0..11).
encode {
    br 6
}

# Explicit level and window size (lgwin, 10..24).
encode {
    br 6 22
}
```

### Options

| Option  | Range | Default | Description                                                                 |
| ------- | ----- | ------- | --------------------------------------------------------------------------- |
| `level` | 0..11 | 4       | Compression level. Higher compresses more but is slower. `0` is the fastest. |
| `lgwin` | 10..24| 22      | Base-2 logarithm of the sliding window size. Larger windows compress more.  |


### JSON config

```json
{
  "handler": "encode",
  "encodings": { "br": { "level": 6, "lgwin": 22 } },
  "prefer": ["br"]
}
```

## Benchmarks

Measured on an AWS **c7g.large** spot instance: Graviton3 (arm64). See the
[bench branch](https://github.com/fuckoffel/caddy-brotli/tree/bench/bench) for
the setup. Comparing `zstd level default` and `brotli level 3` of this plugin and
[ueffel/caddy-brotli](https://github.com/ueffel/caddy-brotli).

| File             | Raw    | zstd ratio | zstd req/s | br ratio | this plugin req/s | ueffel req/s |
|------------------|--------|------------|------------|----------|-------------------|--------------|
| `mdn.html`       | 195 KB | 0.147      | 1698       | 0.138    | **1638**          | 875          |
| `amazon.html`    | 811 KB | 0.201      | 373        | 0.195    | **369**           | 189          |
| `nytimes.html`   | 1.0 MB | 0.144      | 393        | 0.130    | **395**           | 191          |
| `wikipedia.html` | 1.0 MB | 0.197      | 283        | 0.190    | **265**           | 139          |
