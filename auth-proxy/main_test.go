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
