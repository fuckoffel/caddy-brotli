package caddybrotli

import (
	"fmt"
	"io"
	"strconv"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/caddyfile"
	"github.com/caddyserver/caddy/v2/modules/caddyhttp/encode"
	"github.com/molecule-man/go-brrr"
)

func init() {
	caddy.RegisterModule(Brotli{})
}

const defaultLevel = 4

// Brotli creates streaming brotli encoders backed by go-brrr.
type Brotli struct {
	// Level is the compression level, 0..11. A nil pointer selects the default
	Level *int `json:"level,omitempty"`

	// LGWin is the base-2 logarithm of the sliding window size, 10..24. Default is 22
	LGWin int `json:"lgwin,omitempty"`
}

func (Brotli) CaddyModule() caddy.ModuleInfo {
	return caddy.ModuleInfo{
		ID:  "http.encoders.br",
		New: func() caddy.Module { return new(Brotli) },
	}
}

func (b *Brotli) Provision(_ caddy.Context) error {
	if b.Level == nil {
		def := defaultLevel
		b.Level = &def
	}
	if *b.Level < 0 || *b.Level > 11 {
		return fmt.Errorf("brotli: level must be 0..11, got %d", *b.Level)
	}
	if b.LGWin != 0 && (b.LGWin < 10 || b.LGWin > 24) {
		return fmt.Errorf("brotli: lgwin must be 10..24, got %d", b.LGWin)
	}
	return nil
}

// UnmarshalCaddyfile parses `br [<level> [<lgwin>]]`.
func (b *Brotli) UnmarshalCaddyfile(d *caddyfile.Dispenser) error {
	d.Next()
	args := d.RemainingArgs()
	switch len(args) {
	case 0:
	case 1, 2:
		level, err := strconv.Atoi(args[0])
		if err != nil {
			return d.Errf("invalid level %q: %v", args[0], err)
		}
		b.Level = &level
		if len(args) == 2 {
			lgwin, err := strconv.Atoi(args[1])
			if err != nil {
				return d.Errf("invalid lgwin %q: %v", args[1], err)
			}
			b.LGWin = lgwin
		}
	default:
		return d.ArgErr()
	}
	return nil
}

func (Brotli) AcceptEncoding() string { return "br" }

func (b Brotli) NewEncoder() encode.Encoder {
	w, err := brrr.NewWriterOptions(io.Discard, *b.Level, brrr.WriterOptions{LGWin: b.LGWin})
	if err != nil {
		// Provision validates level and lgwin, so this is unreachable.
		panic(err)
	}
	return w
}

var (
	_ encode.Encoding       = (*Brotli)(nil)
	_ caddy.Provisioner     = (*Brotli)(nil)
	_ caddyfile.Unmarshaler = (*Brotli)(nil)
)
