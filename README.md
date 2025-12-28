# TWICH Coin

TWICH is a fixed-supply token built on the **Sui blockchain**, designed for community use, experimentation, and digital interaction.  
The token has immutable metadata, a capped supply, and an on-chain vesting mechanism to ensure transparent distribution.

> TWICH is **not affiliated with any streaming platform**.

---

## 📌 Token Overview

| Property | Value |
|--------|-------|
| Name | TwichCoin |
| Symbol | TWICH |
| Blockchain | Sui |
| Decimals | 9 |
| Total Supply | 1,000,000,000 TWICH |
| Minting | Disabled (fixed supply) |
| Metadata | Immutable |
| Vesting | On-chain, time-based |

---

## 📦 Supply & Vesting Model

- **Total supply:** 1,000,000,000 TWICH  
- **Initial distribution:**  
  - 90% released immediately  
  - 10% locked in a vesting pool  

### Vesting schedule
| Portion | Unlock time |
|--------|-------------|
| 5% | After 1 year |
| 5% | After 2 years |

Vesting is enforced fully on-chain and cannot be bypassed.

---

## 🔐 Security Properties

- ✅ Fixed supply (minting permanently disabled)
- ✅ Metadata permanently locked
- ✅ No admin mint authority
- ✅ Deterministic vesting rules
- ✅ Fully on-chain enforcement
- ✅ No upgrade hooks

---

## 🧱 Contract Architecture

Main components:

- **TWICHCOIN** — coin type definition
- **VestingPool** — manages locked token release
- Uses Sui `coin_registry` with OTW (one-time witness)
- Metadata finalized and deleted at deployment
- Uses Sui clock for time-based unlocking

---

## 📂 Repository Structure

├── sources/
│ └── twichcoin.move
├── tests/
│ └── twichcoin_tests.move
├── Move.toml
├── README.md
└── LICENSE

## 🧪 Testing

Run unit tests locally:

```bash
sui move test
Tests cover:

vesting initialization

beneficiary setup

unlock timing logic

balance visibility helpers


Deployment Notes

Metadata is finalized at deployment time and cannot be changed.

Token supply is permanently fixed.

Contract is suitable for public explorers and wallets.

Designed to be simple, auditable, and deterministic.

Disclaimer

TWICH is experimental software provided as-is, without warranty of any kind.
It does not represent equity, ownership, or financial rights in any organization.

Use at your own risk.

License

MIT License - see LICENSE file for details.
