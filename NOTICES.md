# Notices

This project includes or installs content from the following third-party sources.

---

## BMAD-METHOD

**Source**: [github.com/bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)
**License**: MIT License — Copyright (c) 2025 BMad Code, LLC

The methodology skills in `skills/methodology/` are derived from BMAD-METHOD. Modifications: persona name substitutions (Mary to Justin, Paige to Bri, John to Nicole, Sally to Kaan, Winston to Tyler, Amelia to Elliot) to match the SDF DevRel team; `bmad-` prefix dropped from skill names; `bmad-help` renamed to `stellar-help`. The underlying skill structure, descriptions, and methodology content are otherwise preserved from upstream.

Full MIT License text:

```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## stellar/stellar-dev-skill

**Source**: [github.com/stellar/stellar-dev-skill](https://github.com/stellar/stellar-dev-skill)
**License**: Apache License 2.0

The 7 Stellar dev knowledge modules (`soroban`, `dapp`, `assets`, `data`, `agentic-payments`, `zk-proofs`, `standards`) are fetched directly from the canonical upstream repo at install time. No modifications.

License: https://www.apache.org/licenses/LICENSE-2.0

---

## electric-capital/open-dev-data

**Source**: [github.com/electric-capital/open-dev-data](https://github.com/electric-capital/open-dev-data)
**License**: Code under MIT License; data under Creative Commons Attribution 4.0 International (CC-BY 4.0)

Stellar developer activity data (`skills/data/electric-capital/stellar-repos.json`) is derived from the Electric Capital taxonomy via the `open-dev-data` CLI tool. Attribution to Electric Capital under CC-BY 4.0.

---

## lumenloop/awesome-stellar-community-fund

**Source**: [github.com/lumenloop/awesome-stellar-community-fund](https://github.com/lumenloop/awesome-stellar-community-fund)

The 10 SCF lifecycle skills are fetched directly from the upstream repo at install time. No modifications. Attribution: LumenLoop.

---

## lumenloop/stellar-ecosystem-db

**Source**: [github.com/lumenloop/stellar-ecosystem-db](https://github.com/lumenloop/stellar-ecosystem-db)

The 728-project ecosystem database (YAML files in `projects/`) is fetched at install time and converted to JSON for skill consumption. Attribution: LumenLoop.

---

## stellar/ecosystem-resources

**Source**: [github.com/stellar/ecosystem-resources](https://github.com/stellar/ecosystem-resources)

Curated reference documentation (subset of small-text folders) is included in `skills/data/guides/`. Heavy folders (`connect-wallet/`, `guestbook/`, `openzeppelin/`) are referenced via link rather than redistributed. Attribution: Stellar Development Foundation.

---

## Inspiration: solana.new

The install pattern and skill-router architecture are inspired by [solana.new](https://www.solana.new) by SendAI and Superteam. No code or content is copied; only the architectural pattern.
