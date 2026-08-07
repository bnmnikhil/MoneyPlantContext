# research/

Background research that informs design decisions but is not code-truth. Unlike `CLAUDE.md`, these do not get regenerated from the codebase — they are dated snapshots of the outside world, and the outside world moves. Re-check before relying on a date or a price.

| Doc | Question it answers | Researched |
|---|---|---|
| [`REGULATORY-API-STATIC-IP.md`](REGULATORY-API-STATIC-IP.md) | What SEBI, NSE and the three brokers require of API trading — static IPs, API keys, algo status, and what changes if MoneyPlant ever places an order | 6 Aug 2026 |
| [`IPV4-VS-IPV6-STATIC-IP.md`](IPV4-VS-IPV6-STATIC-IP.md) | Whether the IPv6 path works end to end, what each protocol costs, and the cheapest place to buy an address that survives a VM resize | 6 Aug 2026 |

## sources/

Primary documents, archived because regulator and exchange URLs rot and get superseded. Stored as `pdftotext -layout` extractions only — the PDFs were dropped to keep the repo light, so **re-download the PDF before quoting anything load-bearing**, since layout extraction can mangle a page break (see the artefact below).

| File | Document |
|---|---|
| `sebi-CIR-2025-0000013-retail-algo-2025-02-04.*` | SEBI, *Safer participation of retail investors in Algorithmic trading*, 4 Feb 2025 — the source of the static IP and API key clauses |
| `nse-INVG67858-implementation-standards-2025-05-05.*` | NSE, *Implementation Standards*, 5 May 2025 — the operative mechanics: one primary + one secondary IP, weekly change limit, one-client-per-IP, 10 OPS |
| `nse-faq-retail-algo-2025-11-03.*` | NSE, *FAQs*, 3 Nov 2025 — narrows the static IP requirement to order placement, and confirms every API order is an algo order |

⚠ **Known extraction artefact:** in `nse-INVG67858…txt`, item B.3 loses a negation across a page break and reads as though below-threshold algos *require* exchange registration. They do not. Check the PDF before quoting that item.

Not archived, but cited in the docs above: SEBI's extension circular (`SEBI/HO/MIRSD/MIRSD-PoD/P/CIR/2025/132`, 30 Sep 2025), NSE/INVG/69255 (22 Jul 2025, detailed operational modalities — **never read in full**, only the paragraphs the FAQ quotes), and NSE/INVG/70309 (19 Sep 2025, empanelment criteria).
