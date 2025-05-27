# FractkMarket - Property Tokenization on Starknet

This project implements an ERC-1155 token contract for property tokenization on Starknet.

## Project Structure

```
contracts-starknet/
├── src/
│   ├── lib.cairo              # Main library file
│   └── property_token.cairo   # ERC-1155 property token contract
├── Scarb.toml                 # Project configuration
└── README.md                  # This file
```

## Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/download.html) - Cairo package manager
- [Starknet CLI](https://docs.starknet.io/documentation/tools/cli/installation/) - For deploying to Starknet

## Setup

1. Install Scarb:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
```

2. Build the project:
```bash
scarb build
```

## Contract Features

- ERC-1155 standard implementation
- Owner-based access control
- Secure minting functionality (only owner can mint)
- Event emission for transfers
- Balance tracking

## Contract Functions

- `mint(to: ContractAddress, id: u256, amount: u256)`: Mints new tokens (only owner)
- `balance_of(account: ContractAddress, id: u256) -> u256`: Returns the balance of tokens for a specific account and ID

## Example Usage

```cairo
// Mint 100 tokens with ID 1 to an address (only owner can do this)
mint(recipient_address, 1, 100);

// Check balance
let balance = balance_of(recipient_address, 1);
```

## Security Features

- Owner-based access control for minting
- Proper event emission for all state changes
- Safe balance and supply tracking
- Immutable owner after deployment

## Development

1. Compile contracts:
```bash
scarb build
```

2. Run tests (when implemented):
```bash
scarb test
```

## Deployment

The contract is designed to be deployed on the Sepolia testnet of Starknet. To deploy:

```bash
starknet deploy --contract target/dev/fractmarket_PropertyToken.sierra.json --network sepolia
```