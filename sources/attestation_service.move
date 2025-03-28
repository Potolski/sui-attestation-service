module attestation_service::attestations {
    use sui::event;
    use sui::table::{Self, Table};
    use std::string::{Self, String};

    // ======== Error Constants ========
    const EUnauthorizedAttester: u64 = 0;
    const EUnauthorizedSchemaCreator: u64 = 1;
    const ESchemaNotFound: u64 = 2;

    // ======== Objects and Events ========

    /// Admin capability that controls who can manage the registry
    public struct AdminCap has key {
        id: UID
    }

    /// The registry that stores schema definitions
    public struct SchemaRegistry has key {
        id: UID,
        schemas: Table<ID, SchemaInfo>,
        // List of addresses authorized to create schemas
        // If empty, anyone can create schemas
        authorized_schema_creators: vector<address>
    }

    /// Information about a registered schema
    public struct SchemaInfo has store, copy, drop {
        name: String,
        description: String,
        creator: address,
        revocable: bool,
        // List of addresses authorized to create attestations with this schema
        // If empty, anyone can create attestations
        authorized_attesters: vector<address>
    }

    /// An attestation created using a schema
    public struct Attestation has key {
        id: UID,
        schema_id: ID,
        attester: address,
        subject: address,
        timestamp: u64,
        revoked: bool,
        data: String // JSON string containing attestation data
    }

    /// Index for querying attestations by subject
    public struct SubjectIndex has key {
        id: UID,
        // Maps subjects to their attestation IDs
        subject_to_attestations: Table<address, vector<ID>>
    }

    /// Index for querying attestations by schema
    public struct SchemaIndex has key {
        id: UID,
        // Maps schema IDs to their attestation IDs
        schema_to_attestations: Table<ID, vector<ID>>
    }

    /// Event emitted when a new schema is registered
    public struct SchemaRegistered has copy, drop {
        schema_id: ID,
        name: String,
        creator: address
    }

    /// Event emitted when a new attestation is created
    public struct AttestationCreated has copy, drop {
        attestation_id: ID,
        schema_id: ID,
        attester: address,
        subject: address
    }

    /// Event emitted when an attestation is revoked
    public struct AttestationRevoked has copy, drop {
        attestation_id: ID,
        schema_id: ID,
        attester: address
    }

    // ======== Functions ========

    /// Initialize the attestation service
    fun init(ctx: &mut TxContext) {
        // Create admin capability
        let admin_cap = AdminCap {
            id: object::new(ctx)
        };
        
        // Create and share the schema registry
        let registry = SchemaRegistry {
            id: object::new(ctx),
            schemas: table::new(ctx),
            authorized_schema_creators: vector::empty()
        };

        // Create subject index
        let subject_index = SubjectIndex {
            id: object::new(ctx),
            subject_to_attestations: table::new(ctx)
        };

        // Create schema index
        let schema_index = SchemaIndex {
            id: object::new(ctx),
            schema_to_attestations: table::new(ctx)
        };
        
        // Transfer admin cap to the deployer
        transfer::transfer(admin_cap, tx_context::sender(ctx));
        
        // Share objects
        transfer::share_object(registry);
        transfer::share_object(subject_index);
        transfer::share_object(schema_index);
    }

    /// Update authorized schema creators
    public entry fun update_schema_creators(
        _: &AdminCap,
        registry: &mut SchemaRegistry,
        creators: vector<address>
    ) {
        registry.authorized_schema_creators = creators;
    }

    /// Check if an address is authorized to create schemas
    fun is_authorized_schema_creator(
        registry: &SchemaRegistry,
        creator: address
    ): bool {
        let creators = &registry.authorized_schema_creators;
        
        // If the list is empty, anyone can create schemas
        if (vector::length(creators) == 0) {
            return true
        };
        
        // Otherwise, check if the creator is in the list
        let mut i = 0;
        let len = vector::length(creators);
        while (i < len) {
            if (*vector::borrow(creators, i) == creator) {
                return true
            };
            i = i + 1;
        };
        
        false
    }

    /// Register a new schema
    public entry fun register_schema(
        registry: &mut SchemaRegistry,
        name: vector<u8>,
        description: vector<u8>,
        revocable: bool,
        authorized_attesters: vector<address>,
        ctx: &mut TxContext
    ) {
        let creator = tx_context::sender(ctx);
        
        // Check if the creator is authorized
        assert!(is_authorized_schema_creator(registry, creator), EUnauthorizedSchemaCreator);
        
        let name_str = string::utf8(name);
        let desc_str = string::utf8(description);
        
        // Create schema info
        let schema_info = SchemaInfo {
            name: name_str,
            description: desc_str,
            creator,
            revocable,
            authorized_attesters
        };
        
        // Create a unique ID for the schema
        let schema_uid = object::new(ctx);
        let schema_id = object::uid_to_inner(&schema_uid);
        
        // Store schema in registry
        table::add(&mut registry.schemas, schema_id, schema_info);
        
        // Destroy the temporary UID
        object::delete(schema_uid);
        
        // Emit event
        event::emit(SchemaRegistered {
            schema_id,
            name: name_str,
            creator
        });
    }

    /// Check if an address is authorized to create attestations for a schema
    fun is_authorized_attester(
        schema_info: &SchemaInfo,
        attester: address
    ): bool {
        let attesters = &schema_info.authorized_attesters;
        
        // If the list is empty, anyone can create attestations
        if (vector::length(attesters) == 0) {
            return true
        };
        
        // Otherwise, check if the attester is in the list
        let mut i = 0;
        let len = vector::length(attesters);
        while (i < len) {
            if (*vector::borrow(attesters, i) == attester) {
                return true
            };
            i = i + 1;
        };
        
        false
    }

    /// Create a new attestation using a registered schema
    public entry fun create_attestation(
        registry: &SchemaRegistry,
        subject_index: &mut SubjectIndex,
        schema_index: &mut SchemaIndex,
        schema_id: ID,
        subject: address,
        data: vector<u8>,
        ctx: &mut TxContext
    ) {
        // Get schema info
        assert!(table::contains(&registry.schemas, schema_id), ESchemaNotFound);
        let schema_info = table::borrow(&registry.schemas, schema_id);
        
        let attester = tx_context::sender(ctx);
        
        // Check if attester is authorized
        assert!(is_authorized_attester(schema_info, attester), EUnauthorizedAttester);
        
        // Create attestation
        let attestation = Attestation {
            id: object::new(ctx),
            schema_id,
            attester,
            subject,
            timestamp: tx_context::epoch(ctx),
            revoked: false,
            data: string::utf8(data)
        };
        
        let attestation_id = object::id(&attestation);
        
        // Update subject index
        if (!table::contains(&subject_index.subject_to_attestations, subject)) {
            table::add(&mut subject_index.subject_to_attestations, subject, vector::empty<ID>());
        };
        
        let subject_attestations = table::borrow_mut(&mut subject_index.subject_to_attestations, subject);
        vector::push_back(subject_attestations, attestation_id);
        
        // Update schema index
        if (!table::contains(&schema_index.schema_to_attestations, schema_id)) {
            table::add(&mut schema_index.schema_to_attestations, schema_id, vector::empty<ID>());
        };
        
        let schema_attestations = table::borrow_mut(&mut schema_index.schema_to_attestations, schema_id);
        vector::push_back(schema_attestations, attestation_id);
        
        // Transfer attestation to the attester
        transfer::transfer(attestation, attester);
        
        // Emit event
        event::emit(AttestationCreated {
            attestation_id,
            schema_id,
            attester,
            subject
        });
    }

    /// Revoke an attestation (only the attester can revoke)
    public entry fun revoke_attestation(
        attestation: &mut Attestation,
        ctx: &TxContext
    ) {
        // Only the attester can revoke
        assert!(attestation.attester == tx_context::sender(ctx), EUnauthorizedAttester);
        
        // Mark as revoked
        attestation.revoked = true;
        
        // Emit event
        event::emit(AttestationRevoked {
            attestation_id: object::id(attestation),
            schema_id: attestation.schema_id,
            attester: attestation.attester
        });
    }

    /// Verify if an attestation is valid (not revoked)
    public fun is_valid_attestation(attestation: &Attestation): bool {
        !attestation.revoked
    }

    /// Get schema info by ID
    public fun get_schema_info(registry: &SchemaRegistry, schema_id: ID): SchemaInfo {
        assert!(table::contains(&registry.schemas, schema_id), ESchemaNotFound);
        *table::borrow(&registry.schemas, schema_id)
    }
    
    /// Get all attestation IDs for a subject
    public fun get_attestations_by_subject(
        subject_index: &SubjectIndex, 
        subject: address
    ): vector<ID> {
        if (!table::contains(&subject_index.subject_to_attestations, subject)) {
            return vector::empty<ID>()
        };
        
        *table::borrow(&subject_index.subject_to_attestations, subject)
    }
    
    /// Get all attestation IDs for a schema
    public fun get_attestations_by_schema(
        schema_index: &SchemaIndex,
        schema_id: ID
    ): vector<ID> {
        if (!table::contains(&schema_index.schema_to_attestations, schema_id)) {
            return vector::empty<ID>()
        };
        
        *table::borrow(&schema_index.schema_to_attestations, schema_id)
    }
    
    /// Get attestation details
    public fun get_attestation_details(
        attestation: &Attestation
    ): (ID, address, address, u64, bool, String) {
        (
            attestation.schema_id,
            attestation.attester,
            attestation.subject,
            attestation.timestamp,
            attestation.revoked,
            attestation.data
        )
    }
}