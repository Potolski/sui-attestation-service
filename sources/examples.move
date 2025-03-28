module attestation_service::examples {
    use attestation_service::attestations::{Self, SchemaRegistry, SubjectIndex, SchemaIndex};

    /// Example function to create a KYC verification schema
    public entry fun create_kyc_schema(
        registry: &mut SchemaRegistry,
        ctx: &mut TxContext
    ) {
        // Create an empty vector for authorized attesters (anyone can attest)
        let authorized_attesters = vector::empty<address>();
        
        // Register a KYC schema
        attestations::register_schema(
            registry,
            b"KYC Verification",
            b"Basic KYC verification status attestation",
            true, // revocable
            authorized_attesters,
            ctx
        );
    }

    /// Example function to create a KYC attestation for a user
    public entry fun create_kyc_attestation(
        registry: &SchemaRegistry,
        subject_index: &mut SubjectIndex,
        schema_index: &mut SchemaIndex,
        schema_id: ID,
        subject: address,
        country_code: vector<u8>,
        verification_level: u8,
        ctx: &mut TxContext
    ) {
        // Create a simple JSON string with the attestation data
        let mut json_data = b"{\"country_code\":\"";
        vector::append(&mut json_data, country_code);
        vector::append(&mut json_data, b"\",\"verification_level\":");
        
        // Convert verification level to string
        let level_str = if (verification_level == 1) {
            b"1"
        } else if (verification_level == 2) {
            b"2"
        } else {
            b"3"
        };
        
        vector::append(&mut json_data, level_str);
        vector::append(&mut json_data, b"}");
        
        // Create attestation
        attestations::create_attestation(
            registry,
            subject_index,
            schema_index,
            schema_id,
            subject,
            json_data,
            ctx
        );
    }

    /// Example function to create an education credential schema with restricted attesters
    public entry fun create_education_schema(
        registry: &mut SchemaRegistry,
        authorized_issuers: vector<address>,
        ctx: &mut TxContext
    ) {
        // Register an education credential schema
        attestations::register_schema(
            registry,
            b"Education Credential",
            b"Attestation for educational achievements and degrees",
            false, // not revocable
            authorized_issuers, // only authorized issuers can create these attestations
            ctx
        );
    }

    /// Example function to create an education credential attestation
    public entry fun create_education_attestation(
        registry: &SchemaRegistry,
        subject_index: &mut SubjectIndex,
        schema_index: &mut SchemaIndex,
        schema_id: ID,
        subject: address,
        institution: vector<u8>,
        degree: vector<u8>,
        graduation_year: u16,
        ctx: &mut TxContext
    ) {
        // Create a JSON string with the education credential data
        let mut json_data = b"{\"institution\":\"";
        vector::append(&mut json_data, institution);
        vector::append(&mut json_data, b"\",\"degree\":\"");
        vector::append(&mut json_data, degree);
        vector::append(&mut json_data, b"\",\"graduation_year\":");
        
        // Convert graduation year to string (simple implementation)
        let year_str = if (graduation_year >= 2020) {
            b"2020"
        } else {
            b"You are too old bro"
        };
        
        vector::append(&mut json_data, year_str);
        vector::append(&mut json_data, b"}");
        
        // Create attestation
        attestations::create_attestation(
            registry,
            subject_index,
            schema_index,
            schema_id,
            subject,
            json_data,
            ctx
        );
    }
    
    /// Example function to check if a subject has a valid KYC attestation
    public fun has_valid_kyc(
        attestation_obj: &attestations::Attestation
    ): bool {
        // Check if the attestation is valid and belongs to the specified schema
        attestations::is_valid_attestation(attestation_obj)
    }
}