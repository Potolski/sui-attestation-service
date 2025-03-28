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
