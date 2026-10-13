# Public IP Provider lookup

## Decision (2026-10-13, T-0034)

Keep icanhazip.com as the independent public-IP source. Enrich that exact address using GeoJS's HTTPS Geo endpoint and its `organization_name` field. This identifies the public egress network operator, which can be a VPN or corporate gateway rather than the local access ISP. No commercial brand-name accuracy is promised.

GeoJS requires no account or token. Its current general documentation has no fixed quota; its terms permit throttling/blocking excessive use and provide no availability or data-accuracy warranty. The reviewed terms do not impose an internal-use-only or noncommercial-only restriction. The service endpoint is publicly documented for application integration. No data subscription, database redistribution, or bundled database is involved. Help credits GeoJS and its MaxMind GeoLite data source and links terms/privacy.

The existing IP lookup remains separate so enrichment failure cannot remove an available IP or change reachability. A combined response would save one cold request but couple that information to an enrichment service's availability and egress route. Querying the exact normalized IP also avoids accidentally pairing an IPv6 provider response with an IPv4 address discovered by another service.

## Alternatives investigated

- IPinfo Lite supports IP/ASN organization information but requires a user/account token. Its public legacy endpoint has a quota shared by public IP. No shared token is embedded in this source or distributed binary.
- ipwho.is supports HTTPS and credential-free queries, but its terms describe personal/internal-business licensing and restrict redistribution. Its desktop distribution applicability was not established, so it was not selected.
- RIPEstat provides public routing/ASN information but asks commercial users to contact the operator; it would also identify routing holders rather than guarantee an access ISP.
- ipapi.is has an anonymous tier with a small shared-address quota and restrictive licensing language; it was not selected.
- IP Guide returned network data, but an authoritative service usage/distribution policy was not established.

No account, paid tier, credential provisioning/storage/rotation, or backend is necessary for the selected implementation. Switching to an authenticated service would require revisiting per-user credentials (for example Keychain storage) and distribution terms. A shared secret cannot be kept secret in a public desktop binary. Backend or subscription work requires separate authorization.

## Runtime behavior

- Lookup only after a valid current IP arrives from an event-driven refresh. Menu opening and the minute-based reachability safety check do not initiate enrichment.
- Success cache: normalized IP key, 24-hour expiration checked on the next eligible event, memory-only, at most 32 entries. No new polling timer or persistent IP history.
- Coalesce pending same-IP requests. On network changes cancel old work, clear displayed egress state and ignore obsolete responses using generation identities.
- Failures/missing names: retain ordinary Internet/IP information, hide Provider, and suppress repeat queries for that IP for 60 seconds. A later eligible event may retry; there is no retry loop.
- HTTP 429: apply service-wide cooldown, honoring numeric or HTTP-date Retry-After with a minimum of 60 seconds; malformed/missing values use 60 seconds.
- Five-second request timeout. Reject non-200 responses, invalid/mismatched response IP, malformed data, unknown/empty provider, control characters and overlong names.
- Disabling internet checking clears cached Provider data. Expensive/constrained paths suppress captive/IP/provider probes. Sleep cancels pending work; wake refreshes when allowed.
- All reachability and provider state mutations/notifications run on the main thread. JSON parsing is small and bounded before decoding; networking remains asynchronous.
- Provider appears on a separate copyable row beside Internet. Copy All includes available public-IP/provider values under the same visibility conditions.

## Data disclosure

GeoJS receives the queried public IP and request source IP through its Cloudflare-backed service. WhichAP sends no SSID, BSSID, AP mapping, or connection history. The response includes geographical fields, but WhichAP decodes only IP and organization name. GeoJS's privacy policy describes error logs and third-party infrastructure; do not describe the request as anonymous or promise that no infrastructure logs exist.

## Sources reviewed

- [GeoJS Geo endpoint](https://www.geojs.io/docs/v1/endpoints/geo/)
- [GeoJS general information and rate limits](https://www.geojs.io/docs/general/)
- [GeoJS service terms](https://www.geojs.io/tos/)
- [GeoJS privacy](https://www.geojs.io/privacy/)
- [GeoJS data acknowledgement](https://www.geojs.io/)
- [IPinfo API](https://ipinfo.io/developers)
- [IPinfo public quota](https://support.ipinfo.io/hc/en-us/articles/30792479436562-What-Is-the-Difference-Between-Using-the-Authenticated-Free-Plan-and-the-Public-API-With-No-Account)
- [ipwho.is terms](https://ipwhois.io/terms)
- [RIPEstat use](https://data.stat.ripe.net/docs/getting-started/what-is-ripestat)
- [ipapi.is terms](https://ipapi.is/terms.html)

## Verification

`bash scripts/test-provider.sh` compiles production ProviderLookup and presentation helpers, exercising deterministic cache, transport, failure, cancellation and output behavior. Existing menu-bar checks remain separately required. The app build and live UI/resource checks follow docs/checks.md. These focused checks do not constitute a full application suite or CI.

A single live sample of the production lookup against public test addresses on 2026-10-13 measured approximately 102 ms cold / 0.043 ms cached for IPv4, and 67 ms cold / 0.025 ms cached for IPv6. Both returned a provider. These are local observations, not service guarantees or direct menu-opening measurements. Focused checks verify one request during repeated same-IP updates and no enrichment from rendering helpers. Full UI verification is reported separately with delivery evidence.
