# Funnel Auth Proxy

Tailscale Funnel forwards the public VoroGaze URL to `127.0.0.1:8088` on
Elite. Docker Compose publishes the `auth-proxy` service on that loopback port.

The proxy shows a normal `/login` page, validates the shared credentials, sets a
signed `HttpOnly` session cookie, and reverse-proxies authenticated requests to
the Shiny container. This replaces browser-native HTTP basic auth, whose popup
can be hidden or blocked by some clients.

Create the deployment-local secret file from `auth.env.example`:

```text
funnel-proxy/auth.env
```

Do not commit `auth.env` or old credential text files.
