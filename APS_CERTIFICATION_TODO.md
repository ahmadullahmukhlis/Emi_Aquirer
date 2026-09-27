# APS certification TODO

This repository implements the **acquirer-only** behaviours defined by the supplied APS implementation blueprint.  The following production parameters must be confirmed with APS/SmartVista and must not be guessed.

- Certified production MTIs and original-data elements for reversal/advice and network-management traffic.
- Institution/acquirer identifiers, routing, merchant and terminal registration values.
- The configured six-digit processing code for Card-to-Card; the APS overview identifies a `50XXXX` family while the sample is inconsistent.
- Final DE48 TLV layout, mandatory fields, encoding, bitmap, MAC and framing rules for the bank profile.
- Production TLS/VPN/mTLS settings, certificate lifecycle and SmartVista H2H endpoint details.
- HSM vendor interface, key ceremony, PIN-block formats, MAC keys and cryptographic key aliases.
- Per-channel authentication profile: EMV/CVM/PIN/OTP requirements, including permitted CNP and mobile use cases.
- Terminal SDK/device certification, P2PE/PCI scope, EMV contact/contactless and fallback rules.
- APS reconciliation file format, delivery channel, matching keys, end-of-day and DAB settlement procedure.
- APS/issuer-approved response-code mapping and retry/reversal timing for codes 811, 835, 931, 940, 959 and 961–963.
- Approved FX-rate authority and disclosure requirements for cross-currency transactions.

No real PAN, CVV, PIN, PIN block, OTP, clear key material or production secret belongs in this repository.
