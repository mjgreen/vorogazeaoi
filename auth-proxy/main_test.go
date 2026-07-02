package main

import (
	"net/url"
	"testing"
	"time"

	"golang.org/x/crypto/bcrypt"
)

func TestSessionTokenRoundTrip(t *testing.T) {
	hash, err := bcrypt.GenerateFromPassword([]byte("secret"), bcrypt.MinCost)
	if err != nil {
		t.Fatal(err)
	}
	upstream, _ := url.Parse("http://example.test")
	s := &server{cfg: config{
		UpstreamURL:  upstream,
		Username:     "tester",
		PasswordHash: hash,
		SessionKey:   []byte("0123456789abcdef0123456789abcdef"),
		CookieName:   "test_session",
		SessionTTL:   time.Hour,
	}}

	if !s.validCredentials("tester", "secret") {
		t.Fatal("expected credentials to be valid")
	}
	if s.validCredentials("tester", "wrong") {
		t.Fatal("expected wrong password to be rejected")
	}
	token, err := s.newSessionToken("tester")
	if err != nil {
		t.Fatal(err)
	}
	if token == "" {
		t.Fatal("expected non-empty token")
	}
}

func TestSanitizeNext(t *testing.T) {
	cases := map[string]string{
		"":                    "/",
		"https://example.com": "/",
		"//example.com":       "/",
		"/":                   "/",
		"/poster?a=1":         "/poster?a=1",
	}
	for input, want := range cases {
		if got := sanitizeNext(input); got != want {
			t.Fatalf("sanitizeNext(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestServerSanitizeNextWithBasePath(t *testing.T) {
	upstream, _ := url.Parse("http://example.test")
	s := &server{cfg: config{
		BasePath:    "/vorogazeaoi",
		UpstreamURL: upstream,
	}}
	cases := map[string]string{
		"":                         "/vorogazeaoi",
		"/":                        "/vorogazeaoi",
		"/login":                   "/vorogazeaoi",
		"/vorogazeaoi":             "/vorogazeaoi",
		"/vorogazeaoi/":            "/vorogazeaoi/",
		"/vorogazeaoi/plot?a=1":    "/vorogazeaoi/plot?a=1",
		"https://example.com/path": "/vorogazeaoi",
		"//example.com/path":       "/vorogazeaoi",
	}
	for input, want := range cases {
		if got := s.sanitizeNext(input); got != want {
			t.Fatalf("sanitizeNext(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestNormalizeBasePath(t *testing.T) {
	cases := map[string]string{
		"":                "",
		"/":               "",
		"/vorogazeaoi":    "/vorogazeaoi",
		"/vorogazeaoi///": "/vorogazeaoi",
	}
	for input, want := range cases {
		got, err := normalizeBasePath(input)
		if err != nil {
			t.Fatalf("normalizeBasePath(%q) returned error: %v", input, err)
		}
		if got != want {
			t.Fatalf("normalizeBasePath(%q) = %q, want %q", input, got, want)
		}
	}

	if _, err := normalizeBasePath("vorogazeaoi"); err == nil {
		t.Fatal("expected relative base path to be rejected")
	}
}

func TestStripBasePath(t *testing.T) {
	cases := map[string]string{
		"/vorogazeaoi":         "/",
		"/vorogazeaoi/":        "/",
		"/vorogazeaoi/session": "/session",
		"/other":               "/other",
	}
	for input, want := range cases {
		u := &url.URL{Path: input}
		stripBasePath(u, "/vorogazeaoi")
		if u.Path != want {
			t.Fatalf("stripBasePath(%q) = %q, want %q", input, u.Path, want)
		}
	}
}
