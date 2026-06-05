## Setup

On a fresh Amazon Linux instance:

```bash
./bootstrap.sh
source /etc/profile.d/go.sh
./build.sh
```

## Corpus

I ran the benchmarks on the following corpus. The files are not committed due to
potential copyright issues.

| File             | Size  | Source URL                                              |
|------------------|-------|---------------------------------------------------------|
| `wikipedia.html` | ~1 MB | https://en.wikipedia.org/wiki/United_States             |
| `mdn.html`       | ~195 KB | https://developer.mozilla.org/en-US/docs/Web/JavaScript |
| `amazon.html`    | ~810 KB | https://www.amazon.com/                                 |
| `nytimes.html`   | ~1 MB | https://www.nytimes.com/international/                  |

## Running

```bash
./bench.sh both                # this vs ueffel, with zstd baseline (default)
./bench.sh this                # only this plugin (+ zstd)
./bench.sh ueffel              # only ueffel (+ zstd)
```

Env variables:

| Var           | Default        | Meaning                                                  |
|---------------|----------------|----------------------------------------------------------|
| `LEVEL`       | `4`            | brotli compression level (0–11)                          |
| `ZLEVEL`      | `default`      | zstd level: `fastest` \| `default` \| `better` \| `best` |
| `FILE`        | `wikipedia.html` | which file under `www/` to serve                       |
| `DURATION`    | `10s`          | `hey` load duration                                      |
| `CONCURRENCY` | `$(nproc)`     | `hey` concurrent connections                             |

## Results

Measured on an AWS **c7g.large** spot instance: Graviton3 (arm64), 2 vCPU /
4 GB, Amazon Linux 2023. Load via `hey`, keepalive on, `-c 2 -z 60s`.
Brotli **level 3**, zstd `default`. Go version v1.26.4 

| File             | Raw    | zstd ratio | zstd req/s | br ratio | this req/s | ueffel req/s |
|------------------|--------|------------|------------|----------|------------|--------------|
| `mdn.html`       | 195 KB | 0.147      | 1698       | 0.138    | 1638       | 875          |
| `amazon.html`    | 811 KB | 0.201      | 373        | 0.195    | 369        | 189          |
| `nytimes.html`   | 1.0 MB | 0.144      | 393        | 0.130    | 395        | 191          |
| `wikipedia.html` | 1.0 MB | 0.197      | 283        | 0.190    | 265        | 139          |


Caveats: single-box benchmark, so `hey` and Caddy share the 2 vCPUs.
