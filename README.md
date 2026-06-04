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
