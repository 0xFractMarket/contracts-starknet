# FractkMarket Smart Contracts

Smart contracts for the tokenized property marketplace on Starknet.

## Structure

```
contracts-starknet/
├── src/
│   ├── contracts/
│   │   └── PropertyToken.cairo        # Main ERC-1155 contract
│   ├── interfaces/
│   │   └── IPropertyToken.cairo       # Contract interfaces
│   └── libraries/
│       └── PropertyMetadata.cairo     # Metadata structures
├── tests/
│   └── test_property_token.cairo      # Contract tests
└── scarb.toml                         # Scarb configuration
```

## Installation

1. Install Scarb:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
```

2. Install dependencies:
```bash
scarb build
```

## Development

1. Compile contracts:
```bash
scarb build
```

2. Run tests:
```bash
scarb test
```

## Deployment

The contracts are designed to be deployed on the Sepolia testnet of Starknet.

## Features

- Property token minting
- Property metadata management
- Fraction transfer
- Property information query