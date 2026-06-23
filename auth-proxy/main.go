package main

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
)

type config struct {
	Listen       string
	UpstreamURL  *url.URL
	Username     string
	PasswordHash []byte
	SessionKey   []byte
	CookieName   string
	CookieSecure bool
	SessionTTL   time.Duration
}

type server struct {
	cfg      config
	proxy    *httputil.ReverseProxy
	loginTpl *template.Template
}

type sessionPayload struct {
	User  string `json:"user"`
	Exp   int64  `json:"exp"`
	Nonce string `json:"nonce"`
}

type contextKey string

const userContextKey contextKey = "authenticatedUser"

func main() {
	cfg, err := loadConfig()
	if err != nil {
		log.Fatal(err)
	}

	proxy := httputil.NewSingleHostReverseProxy(cfg.UpstreamURL)
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalHost := req.Host
		originalDirector(req)
		req.Host = cfg.UpstreamURL.Host
		req.Header.Set("X-Forwarded-Host", originalHost)
		req.Header.Set("X-Forwarded-Proto", forwardedProto(req))
		if user, ok := req.Context().Value(userContextKey).(string); ok && user != "" {
			req.Header.Set("X-Authenticated-User", user)
		}
	}
	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		log.Printf("proxy error for %s: %v", r.URL.Path, err)
		http.Error(w, "The VoroGaze app is temporarily unavailable.", http.StatusBadGateway)
	}

	srv := &server{
		cfg:      cfg,
		proxy:    proxy,
		loginTpl: template.Must(template.New("login").Parse(loginPageHTML)),
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", srv.healthz)
	mux.HandleFunc("/login", srv.login)
	mux.HandleFunc("/logout", srv.logout)
	mux.HandleFunc("/", srv.protectedProxy)

	httpSrv := &http.Server{
		Addr:              cfg.Listen,
		Handler:           securityHeaders(mux),
		ReadHeaderTimeout: 10 * time.Second,
	}

	log.Printf("listening on %s and proxying to %s", cfg.Listen, cfg.UpstreamURL.Redacted())
	log.Fatal(httpSrv.ListenAndServe())
}

func loadConfig() (config, error) {
	rawUpstream := envDefault("VOROGAZE_UPSTREAM_URL", "http://vorogazeaoi:3838")
	upstreamURL, err := url.Parse(rawUpstream)
	if err != nil || upstreamURL.Scheme == "" || upstreamURL.Host == "" {
		return config{}, fmt.Errorf("VOROGAZE_UPSTREAM_URL must be an absolute URL: %q", rawUpstream)
	}

	username := cleanEnv(os.Getenv("VOROGAZE_AUTH_USERNAME"))
	if username == "" {
		return config{}, errors.New("VOROGAZE_AUTH_USERNAME is required")
	}

	passwordHash := cleanEnv(os.Getenv("VOROGAZE_AUTH_BCRYPT"))
	if passwordHash == "" {
		return config{}, errors.New("VOROGAZE_AUTH_BCRYPT is required")
	}

	sessionSecret := cleanEnv(os.Getenv("VOROGAZE_SESSION_SECRET"))
	if len(sessionSecret) < 32 {
		return config{}, errors.New("VOROGAZE_SESSION_SECRET must be at least 32 characters")
	}

	ttlSeconds, err := strconv.Atoi(envDefault("VOROGAZE_SESSION_TTL_SECONDS", "43200"))
	if err != nil || ttlSeconds <= 0 {
		return config{}, errors.New("VOROGAZE_SESSION_TTL_SECONDS must be a positive integer")
	}

	return config{
		Listen:       envDefault("VOROGAZE_AUTH_PROXY_LISTEN", ":8088"),
		UpstreamURL:  upstreamURL,
		Username:     username,
		PasswordHash: []byte(passwordHash),
		SessionKey:   []byte(sessionSecret),
		CookieName:   envDefault("VOROGAZE_COOKIE_NAME", "vorogaze_session"),
		CookieSecure: envBool("VOROGAZE_COOKIE_SECURE", true),
		SessionTTL:   time.Duration(ttlSeconds) * time.Second,
	}, nil
}

func (s *server) healthz(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok\n"))
}

func (s *server) login(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		if _, ok := s.validSessionUser(r); ok {
			http.Redirect(w, r, sanitizeNext(r.URL.Query().Get("next")), http.StatusSeeOther)
			return
		}
		s.renderLogin(w, r, "", http.StatusOK)
	case http.MethodPost:
		if err := r.ParseForm(); err != nil {
			s.renderLogin(w, r, "Could not read the login form.", http.StatusBadRequest)
			return
		}

		username := r.PostForm.Get("username")
		password := r.PostForm.Get("password")
		if !s.validCredentials(username, password) {
			time.Sleep(750 * time.Millisecond)
			s.renderLogin(w, r, "The username or password was not accepted.", http.StatusUnauthorized)
			return
		}

		token, err := s.newSessionToken(username)
		if err != nil {
			log.Printf("could not create session token: %v", err)
			http.Error(w, "Could not start a login session.", http.StatusInternalServerError)
			return
		}

		http.SetCookie(w, &http.Cookie{
			Name:     s.cfg.CookieName,
			Value:    token,
			Path:     "/",
			MaxAge:   int(s.cfg.SessionTTL.Seconds()),
			HttpOnly: true,
			Secure:   s.cfg.CookieSecure,
			SameSite: http.SameSiteLaxMode,
		})
		http.Redirect(w, r, sanitizeNext(r.PostForm.Get("next")), http.StatusSeeOther)
	default:
		w.Header().Set("Allow", "GET, POST")
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (s *server) logout(w http.ResponseWriter, r *http.Request) {
	http.SetCookie(w, &http.Cookie{
		Name:     s.cfg.CookieName,
		Value:    "",
		Path:     "/",
		MaxAge:   -1,
		HttpOnly: true,
		Secure:   s.cfg.CookieSecure,
		SameSite: http.SameSiteLaxMode,
	})
	http.Redirect(w, r, "/login", http.StatusSeeOther)
}

func (s *server) protectedProxy(w http.ResponseWriter, r *http.Request) {
	user, ok := s.validSessionUser(r)
	if !ok {
		http.Redirect(w, r, "/login?next="+url.QueryEscape(currentPath(r)), http.StatusSeeOther)
		return
	}
	s.proxy.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), userContextKey, user)))
}

func (s *server) renderLogin(w http.ResponseWriter, r *http.Request, message string, status int) {
	next := sanitizeNext(firstNonEmpty(r.FormValue("next"), r.URL.Query().Get("next"), "/"))
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	_ = s.loginTpl.Execute(w, map[string]string{
		"Message": message,
		"Next":    next,
	})
}

func (s *server) validCredentials(username, password string) bool {
	if subtle.ConstantTimeCompare([]byte(username), []byte(s.cfg.Username)) != 1 {
		_ = bcrypt.CompareHashAndPassword(s.cfg.PasswordHash, []byte(password))
		return false
	}
	return bcrypt.CompareHashAndPassword(s.cfg.PasswordHash, []byte(password)) == nil
}

func (s *server) newSessionToken(username string) (string, error) {
	nonce := make([]byte, 18)
	if _, err := rand.Read(nonce); err != nil {
		return "", err
	}

	payload := sessionPayload{
		User:  username,
		Exp:   time.Now().Add(s.cfg.SessionTTL).Unix(),
		Nonce: base64.RawURLEncoding.EncodeToString(nonce),
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}

	bodyEncoded := base64.RawURLEncoding.EncodeToString(body)
	sig := s.sign(bodyEncoded)
	return bodyEncoded + "." + sig, nil
}

func (s *server) validSessionUser(r *http.Request) (string, bool) {
	cookie, err := r.Cookie(s.cfg.CookieName)
	if err != nil || cookie.Value == "" {
		return "", false
	}

	parts := strings.Split(cookie.Value, ".")
	if len(parts) != 2 {
		return "", false
	}
	if subtle.ConstantTimeCompare([]byte(s.sign(parts[0])), []byte(parts[1])) != 1 {
		return "", false
	}

	body, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		return "", false
	}

	var payload sessionPayload
	if err := json.Unmarshal(body, &payload); err != nil {
		return "", false
	}
	if payload.User == "" || payload.Exp < time.Now().Unix() {
		return "", false
	}
	return payload.User, true
}

func (s *server) sign(body string) string {
	mac := hmac.New(sha256.New, s.cfg.SessionKey)
	_, _ = mac.Write([]byte(body))
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}

func currentPath(r *http.Request) string {
	path := r.URL.RequestURI()
	if path == "" {
		return "/"
	}
	return path
}

func sanitizeNext(next string) string {
	if next == "" || !strings.HasPrefix(next, "/") || strings.HasPrefix(next, "//") {
		return "/"
	}
	return next
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}

func forwardedProto(r *http.Request) string {
	if proto := r.Header.Get("X-Forwarded-Proto"); proto != "" {
		return proto
	}
	if r.TLS != nil {
		return "https"
	}
	return "http"
}

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Referrer-Policy", "no-referrer")
		w.Header().Set("X-Frame-Options", "DENY")
		next.ServeHTTP(w, r)
	})
}

func envDefault(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func cleanEnv(value string) string {
	value = strings.TrimSpace(value)
	if len(value) >= 2 {
		first := value[0]
		last := value[len(value)-1]
		if (first == '\'' && last == '\'') || (first == '"' && last == '"') {
			return value[1 : len(value)-1]
		}
	}
	return value
}

func envBool(key string, fallback bool) bool {
	value := strings.TrimSpace(strings.ToLower(os.Getenv(key)))
	if value == "" {
		return fallback
	}
	return value == "1" || value == "true" || value == "yes" || value == "on"
}

const loginPageHTML = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>VoroGaze sign in</title>
  <style>
    :root {
      color-scheme: light dark;
      --bg: #f7f8fb;
      --panel: #ffffff;
      --text: #17202a;
      --muted: #5e6b7a;
      --line: #d7dde6;
      --accent: #0f766e;
      --accent-hover: #115e59;
      --danger: #b42318;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #111827;
        --panel: #182231;
        --text: #f4f7fb;
        --muted: #b7c0cd;
        --line: #2f3b4c;
        --accent: #2dd4bf;
        --accent-hover: #5eead4;
        --danger: #fca5a5;
      }
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 24px;
      background: var(--bg);
      color: var(--text);
      font: 16px/1.5 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }
    main {
      width: min(100%, 420px);
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 28px;
      box-shadow: 0 18px 50px rgb(15 23 42 / 12%);
    }
    h1 {
      margin: 0 0 6px;
      font-size: 1.5rem;
      font-weight: 700;
      letter-spacing: 0;
    }
    p {
      margin: 0 0 22px;
      color: var(--muted);
    }
    label {
      display: block;
      margin: 16px 0 6px;
      font-weight: 650;
    }
    input {
      width: 100%;
      min-height: 44px;
      padding: 10px 12px;
      border: 1px solid var(--line);
      border-radius: 6px;
      background: transparent;
      color: var(--text);
      font: inherit;
    }
    button {
      width: 100%;
      min-height: 44px;
      margin-top: 22px;
      border: 0;
      border-radius: 6px;
      background: var(--accent);
      color: #ffffff;
      font: inherit;
      font-weight: 700;
      cursor: pointer;
    }
    button:hover,
    button:focus-visible {
      background: var(--accent-hover);
    }
    .message {
      margin: 16px 0 0;
      color: var(--danger);
      font-weight: 650;
    }
  </style>
</head>
<body>
  <main>
    <h1>VoroGaze</h1>
    <p>Sign in to continue.</p>
    <form method="post" action="/login" autocomplete="on">
      <input type="hidden" name="next" value="{{.Next}}">
      <label for="username">Username</label>
      <input id="username" name="username" type="text" autocomplete="username" required autofocus>
      <label for="password">Password</label>
      <input id="password" name="password" type="password" autocomplete="current-password" required>
      <button type="submit">Sign in</button>
      {{if .Message}}<div class="message">{{.Message}}</div>{{end}}
    </form>
  </main>
</body>
</html>`
