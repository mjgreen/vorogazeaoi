# Auth Proxy

The Beelink LAN front door serves VoroGaze AOI at:

```text
http://192.168.8.205/vorogazeaoi
```

The proxy shows a normal `/vorogazeaoi/login` page, validates the shared
credentials, sets a signed `HttpOnly` session cookie, and reverse-proxies
authenticated requests to the Shiny container. This replaces browser-native HTTP
basic auth, whose popup can be hidden or blocked by some clients.

Create the deployment-local secret file from `auth.env.example`:

```text
funnel-proxy/auth.env
```

Bcrypt hashes contain `$` characters. Keep the `VOROGAZE_AUTH_BCRYPT` value
single-quoted in the env file so Docker Compose passes the hash through
literally instead of treating parts of it as variable references.

Do not commit `auth.env` or old credential text files.
