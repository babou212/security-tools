# headerChecker.sh

A Bash script to crawl a website and check for the presence of key security headers on each page.

## Features

- Crawls all internal pages of a given domain.
- Checks for the following security headers:
  - Strict-Transport-Security
  - Content-Security-Policy
  - X-Content-Type-Options
  - X-Frame-Options
  - X-XSS-Protection
  - Referrer-Policy
  - Permissions-Policy
  - Cross-Origin-Resource-Policy
  - Cross-Origin-Opener-Policy
  - Cross-Origin-Embedder-Policy
- Outputs a report listing which headers are present or missing for each URL.

## Usage

```sh
./headerChecker.sh <domain> [output_file]
```

- `<domain>`: The domain to crawl (e.g., `example.com`)
- `[output_file]`: (Optional) Output file for the report. Defaults to `security_headers_report.txt`.

### Example

```sh
./headerChecker.sh example.com report.txt
```

## Requirements

- Bash
- `curl`
- `grep`
- `cut`
- `sed`
- `sort`

## Output

The script generates a report file listing each crawled URL and the presence or absence of each security header.

---

**Note:** Only HTTPS URLs on the specified domain are crawled. The script does not follow links