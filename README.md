# Sui Attestation Service

A decentralized attestation infrastructure built on the Sui blockchain, enabling verifiable claims and credentials in a trustless environment.

## What is Sui Attestation Service?

Sui Attestation Service (SAS) is a protocol for creating, managing, and verifying claims (attestations) on the Sui blockchain. Inspired by Ethereum Attestation Service (EAS), it provides a flexible and extensible framework for on-chain verification of information.

At its core, SAS allows any entity to:

1. Define schemas for structured attestations
2. Create verifiable attestations about subjects (addresses or objects)
3. Verify and query attestations using efficient indexing
4. Manage attestation lifecycles including revocation

## Why Use Attestations?

Attestations serve as the backbone for trust in decentralized systems. They enable verifiable claims about entities without requiring central authorities. Use cases include:

- KYC/AML verifications
- Educational credentials and certifications
- Reputation systems
- Governance participation rights
- Credit scoring and financial attestations
- Identity verification

## Architecture

SAS consists of several core components:

- **SchemaRegistry**: Stores definitions of attestation formats
- **Attestations**: Verifiable claims about subjects following specific schemas
- **Permission System**: Controls who can create schemas and attestations
- **Indexing System**: Enables efficient querying of attestations by subject or schema

## Features

- Schema-based attestation structure
- Granular permission controls
- Efficient attestation indexing and querying
- Revocation support
- Extensible data model using JSON

## Deployment

This project has been deployed to the Sui testnet with the following objects:

- Package ID: 0xb1f0f64794352052cc97efd38d09c169f4b61bcbce174d6fe9a4d0058b4e53b0
- SchemaRegistry: 0xb25dd2110807bac4ec32d518a181b9ffdaee5f318d674f1f4e19a80a4df9fa96
- SubjectIndex: 0x07e861d3d5d1840b7bcea553e687f1afa1dcbee1f38394b187113ad7c9d14500
- SchemaIndex: 0x205d4400e98c59028ab0c0f30e77ca1a0d677982d932ad48ce8b6afcbf08d798

# Sui Attestation Service Deployment and Testing Guide

## Building the Project

To build the project, run:

```bash
sui move build
```

This will compile your Move modules. If there are any errors, fix them before proceeding.

## Testing Locally

Before deploying to testnet, you should test your modules locally:

```bash
# Create a local test for your modules
sui move test
```

## Deploying to Testnet

Now, let's deploy the modules to the Sui testnet:

```bash
# Make sure you're connected to the testnet
sui client switch --env testnet

# Check your active address
sui client active-address

# Publish the package
sui client publish --gas-budget 100000000
```

After successful publication, you'll receive a response containing the package ID and other important information. Take note of the following:

1. The package ID
2. The `SchemaRegistry` object ID
3. The `SubjectIndex` object ID
4. The `SchemaIndex` object ID
5. The `AdminCap` object ID (this will be owned by your address)

You'll need these IDs for interacting with your deployed modules.

## Interacting with the Deployed Service

### Step 1: Create a Schema

First, let's create a KYC verification schema:

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module examples \
  --function create_kyc_schema \
  --args <SCHEMA_REGISTRY_ID> \
  --gas-budget 10000000
```

After executing this command, you'll receive a transaction response. Look for the `SchemaRegistered` event in the transaction effects to find the schema ID.

### Step 2: Create an Attestation

Now, let's create a KYC attestation for a subject:

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module examples \
  --function create_kyc_attestation \
  --args <SCHEMA_REGISTRY_ID> <SUBJECT_INDEX_ID> <SCHEMA_INDEX_ID> <SCHEMA_ID> <SUBJECT_ADDRESS> '[85, 83]' 2 \
  --gas-budget 10000000
```

This creates a KYC attestation indicating that the subject has level 2 verification in the US (country code "US").

### Step 3: Create a Restricted Schema

Let's create an education credential schema with restricted attesters:

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module examples \
  --function create_education_schema \
  --args <SCHEMA_REGISTRY_ID> '["<YOUR_ADDRESS>"]' \
  --gas-budget 10000000
```

This creates a schema where only your address can create attestations.

### Step 4: Query Attestations

To query attestations for a specific subject, you'll need to use the Sui RPC API. Here's a simple script to do this:

```bash
# Replace with your actual values
SUBJECT_INDEX_ID="<SUBJECT_INDEX_ID>"
SUBJECT_ADDRESS="<SUBJECT_ADDRESS>"

# Get the object
sui client object $SUBJECT_INDEX_ID --json
```

You can also use the Sui Explorer (https://explorer.sui.io/) to view objects and transactions on the testnet.

## Monitoring Events

The attestation service emits events for key actions. You can monitor these events using the Sui RPC API or the Explorer.

## Administrative Actions

If you need to update the list of authorized schema creators, you can use the admin capability:

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module attestations \
  --function update_schema_creators \
  --args <ADMIN_CAP_ID> <SCHEMA_REGISTRY_ID> '["<ADDRESS_1>", "<ADDRESS_2>"]' \
  --gas-budget 10000000
```

This restricts schema creation to the specified addresses.

## Testing Revocation

To revoke an attestation, you need the attestation object ID:

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module attestations \
  --function revoke_attestation \
  --args <ATTESTATION_ID> \
  --gas-budget 10000000
```

Only the original attester can revoke an attestation.

## Troubleshooting

If you encounter issues:

1. **Transaction Errors**: Check the error message in the transaction response
2. **Object Not Found**: Make sure you're using the correct object IDs
3. **Permission Errors**: Verify that you have the necessary permissions
4. **Gas Issues**: Increase the gas budget for complex operations

## Next Steps

1. Adding more features (e.g., delegation, expiration)
2. Sending the attestation as an NFT to the 'subject'
3. Building a frontend interface to track attestation creation
4. Integrating with other Sui modules or applications
5. Deploying to the Sui mainnet (when ready)
