package caddybrotli

import (
	"bytes"
	"strings"
	"testing"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/caddyfile"
	"github.com/molecule-man/go-brrr"
)

func TestProvisionDefaults(t *testing.T) {
	b := Brotli{}
	if err := b.Provision(caddy.Context{}); err != nil {
		t.Fatalf("Provision: %v", err)
	}
	if b.Level == nil || *b.Level != 4 {
		t.Errorf("default level = %v, want 4", b.Level)
	}
	if b.LGWin != 0 {
		t.Errorf("default lgwin = %d, want 0 (go-brrr default)", b.LGWin)
	}
}

func TestProvisionValidation(t *testing.T) {
	cases := []struct {
		name    string
		b       Brotli
		wantErr bool
	}{
		{"level unset ok", Brotli{}, false},
		{"level zero ok", Brotli{Level: ptr(0)}, false},
		{"level too high", Brotli{Level: ptr(12)}, true},
		{"level negative", Brotli{Level: ptr(-1)}, true},
		{"level max ok", Brotli{Level: ptr(11)}, false},
		{"lgwin too low", Brotli{Level: ptr(4), LGWin: 9}, true},
		{"lgwin too high", Brotli{Level: ptr(4), LGWin: 25}, true},
		{"lgwin min ok", Brotli{Level: ptr(4), LGWin: 10}, false},
		{"lgwin max ok", Brotli{Level: ptr(4), LGWin: 24}, false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := tc.b.Provision(caddy.Context{})
			if tc.wantErr != (err != nil) {
				t.Fatalf("Provision err = %v, wantErr = %v", err, tc.wantErr)
			}
		})
	}
}

func TestUnmarshalCaddyfile(t *testing.T) {
	cases := []struct {
		name      string
		input     string
		wantLevel *int
		wantLGWin int
		wantErr   bool
	}{
		{"no args", "br", nil, 0, false},
		{"level zero", "br 0", ptr(0), 0, false},
		{"level only", "br 7", ptr(7), 0, false},
		{"level and lgwin", "br 7 18", ptr(7), 18, false},
		{"bad level", "br x", nil, 0, true},
		{"bad lgwin", "br 7 x", nil, 0, true},
		{"too many args", "br 7 18 1", nil, 0, true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			var b Brotli
			d := caddyfile.NewTestDispenser(tc.input)
			err := b.UnmarshalCaddyfile(d)
			if tc.wantErr != (err != nil) {
				t.Fatalf("UnmarshalCaddyfile err = %v, wantErr = %v", err, tc.wantErr)
			}
			if tc.wantErr {
				return
			}
			if !eqLevel(b.Level, tc.wantLevel) || b.LGWin != tc.wantLGWin {
				t.Errorf("got level=%v lgwin=%d, want level=%v lgwin=%d",
					b.Level, b.LGWin, tc.wantLevel, tc.wantLGWin)
			}
		})
	}
}

func TestAcceptEncoding(t *testing.T) {
	if got := (Brotli{}).AcceptEncoding(); got != "br" {
		t.Errorf("AcceptEncoding = %q, want %q", got, "br")
	}
}

func TestNewEncoderRoundTrip(t *testing.T) {
	payload := []byte(strings.Repeat("the quick brown fox jumps over the lazy dog. ", 200))

	b := Brotli{Level: ptr(5), LGWin: 18}
	if err := b.Provision(caddy.Context{}); err != nil {
		t.Fatalf("Provision: %v", err)
	}

	enc := b.NewEncoder()
	var compressed bytes.Buffer
	enc.Reset(&compressed)
	if _, err := enc.Write(payload); err != nil {
		t.Fatalf("Write: %v", err)
	}
	if err := enc.Close(); err != nil {
		t.Fatalf("Close: %v", err)
	}

	if compressed.Len() >= len(payload) {
		t.Errorf("compressed size %d not smaller than input %d", compressed.Len(), len(payload))
	}

	got, err := brrr.Decompress(compressed.Bytes())
	if err != nil {
		t.Fatalf("Decompress: %v", err)
	}
	if !bytes.Equal(got, payload) {
		t.Fatalf("round trip mismatch: got %d bytes, want %d", len(got), len(payload))
	}
}

func TestNewEncoderLevelZero(t *testing.T) {
	payload := []byte(strings.Repeat("compress me ", 100))

	b := Brotli{Level: ptr(0)}
	if err := b.Provision(caddy.Context{}); err != nil {
		t.Fatalf("Provision: %v", err)
	}

	enc := b.NewEncoder()
	var compressed bytes.Buffer
	enc.Reset(&compressed)
	if _, err := enc.Write(payload); err != nil {
		t.Fatalf("Write: %v", err)
	}
	if err := enc.Close(); err != nil {
		t.Fatalf("Close: %v", err)
	}

	got, err := brrr.Decompress(compressed.Bytes())
	if err != nil {
		t.Fatalf("Decompress: %v", err)
	}
	if !bytes.Equal(got, payload) {
		t.Fatalf("round trip mismatch at level 0")
	}
}

func ptr(i int) *int { return &i }

func eqLevel(a, b *int) bool {
	if a == nil || b == nil {
		return a == b
	}
	return *a == *b
}
