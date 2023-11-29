import credits.leo;

// The 'program' program.
program aleo_name_service_registry_v3.aleo {
    // base uri ascii bits. Include as many data pieces as necessary to encapsulate the uri. Padded with 0s at the end.
    struct BaseURI {
        data0: u128, // Part 1 of the base uri in bits. Bits should be the representation of the hexadecimal bytes for the ASCII text of the URL
        data1: u128,
        data2: u128,
        data3: u128
    }

    // Structure holding a name_hash and its type
    struct ResolverIndex {
        name: field, // The name_hash
        category: u128, // The type of the resolver, can contain 16 characters in maximum
        version: u64 // The version of the name
    }

    // Structure holding the ASCII bits of a domain name. If the length of the bits is less than 512,
    // zeros are appended in the end. The bits are then split into four parts, with name[0] holding the
    // first 128 bits and name[3] holding the last 128 bits.
    struct Name {
        name: [u128; 4],
        parent: field // The name_hash of the parent name
    }

    struct NameStruct {
        name: [u128; 4],
        parent: field,
        resolver: u128 // the resolver program, 0 means current program
    }

    struct AddressPair {
        nft_owner: address,  // the owner of the nft
        nft_operator: address  // the operator of the nft
    }

    struct NameAddressPair {
        name_hash: field,  // the name_hash of the name
        nft_owner: address  // the owner of the nft
    }

    record NFT {
        owner: address,
        data: field,  // this is the name_hash of the name
        edition: scalar
    }

    // a way to prove ownership of an nft privately
    record NFT_ownership {
        owner: address,
        nft_owner: address,
        data: field,  // this is the name_hash of the name
        edition: scalar
    }

    // Mappings for different data structures
    // Store public domain to address
    // For top level domains, the address is the registrar
    mapping nft_owners: field => address;
    // Mapping from a field(hash name) to an NameStruct structure
    mapping names: field => NameStruct;
    // Mapping from an address to a primary name
    mapping primary_names: address => field;
    // Mapping from a ResolverIndex structure to an Name array(string), max 128 ASCII characters
    mapping resolvers: ResolverIndex => [u128; 8];
    // Mapping from a name_hash to a version number
    mapping name_versions: field => u64;

    // nft_owner approved operators to transfer nft
    // we make the address public is because we want others can check which address is approved
    mapping approved_for_all: AddressPair => bool;
    // nft_owner approved address to transfer nft. and make the address public for the same reason
    mapping approved_for_nft: NameAddressPair => address;

    mapping general_settings: u8 => u128;
    mapping toggle_settings: u8 => u32;

    inline calc_name_hash(name: [u128; 4], parent: field) -> field {
        let full_name: Name = Name {
            name: name,
            parent: parent
        };
        return Poseidon2::hash_to_field(full_name);
    }

    // Validate the ASCII bits of a domain name
    inline validate_name_bit(val: u128) -> bool {
        let mask: u128 = 255u128;
        for i: u8 in 0u8 .. 16u8 {
            let new: u128 = val.shr(i * 8u8);
            let b: u128 = new & mask;
            // Check if the ASCII bit is valid, 0-9, a-z, -, _
            if (! (b == 0u128 || b == 45u128 || b == 95u128 || (b >= 48u128 && b <= 57u128) || (b >= 97u128 && b <= 122u128))) {
                return false;
            }
        }
        return true;
    }

    function validate_name(name: [u128; 4]) -> bool {
        // Check if the name is empty
        assert_neq(name[0u8], 0u128);
        let is_valid: bool = true;
        for i: u8 in 0u8 .. 4u8 {
            is_valid = is_valid && validate_name_bit(name[i]);
        }
        return is_valid;
    }

    transition initialize_collection(
        public total: u128,
        public symbol: u128,
        public base_uri: BaseURI,
    ) {
        // set the caller to admin
        let admin: u128 = BHP256::hash_to_u128(self.caller);
        return then finalize(total, symbol, admin, base_uri);
    }

    finalize initialize_collection(
        public total: u128,
        public symbol: u128,
        public admin: u128,
        public base_uri: BaseURI,
    ) {
        // Ensure initialize cannot be called twice!
        let toggle_settings_status: u32 = toggle_settings.get_or_use(0u8, 0u32);
        let is_initialized: u32 = toggle_settings_status & 1u32;
        assert_eq(is_initialized, 0u32);

        general_settings.set(0u8, total); // This setting is for the Leo wallet, no real effect on the contract
        general_settings.set(1u8, total); // This setting is for the Leo wallet, no real effect on the contract
        general_settings.set(2u8, symbol); // Symbol for the NFT
        general_settings.set(3u8, base_uri.data0); // Base URI for NFT
        general_settings.set(4u8, base_uri.data1);
        general_settings.set(5u8, base_uri.data2);
        general_settings.set(6u8, base_uri.data3);
        general_settings.set(7u8, admin); // Admin hash address
        // initialized flag = 0b0000...0001 = 1u32
        // minting flag = 0b0000...0010 = 2u32
        // frozen flag = 0b0000...1000 = 8u32
        // defaults -- not frozen, not minting, initialized
        // 0b0000...0001 = 1u32.
        toggle_settings.set(0u8, 1u32);
        toggle_settings.set(1u8, 0u32); // block height when mint is allowed
    }

    transition set_admin(
        private admin: address
    ) {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        let new_admin: u128 = BHP256::hash_to_u128(admin);
        return then finalize(hash_caller, new_admin);
    }

    finalize set_admin(
        public hash_caller: u128,
        public new_admin: u128
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(7u8));
        general_settings.set(7u8, new_admin); // Admin hash address
    }

    transition set_mint_block(
        public mint_block: u32
    ) {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return then finalize(hash_caller, mint_block);
    }

    finalize set_mint_block(
        public hash_caller: u128,
        public mint_block: u32
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(7u8));
        // Ensure collection is initialized and not frozen.
        let toggle_settings_status: u32 = toggle_settings.get(0u8);
        // initialized & frozen flags = 0b0000...1001 = 9u32
        // what the settings should be = 0b0000...0001 = 1u32
        let is_initialized_and_not_frozen: u32 = toggle_settings_status & 9u32;
        assert_eq(is_initialized_and_not_frozen, 1u32);

        toggle_settings.set(1u8, mint_block);
    }

    transition update_base_uri(
        public base_uri: BaseURI
    ) {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return then finalize(hash_caller, base_uri);
    }

    finalize update_base_uri(
        public hash_caller: u128,
        public base_uri: BaseURI
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(7u8));
        // Ensure collection is initialized and not frozen.
        let toggle_settings_status: u32 = toggle_settings.get(0u8);
        // initialized & frozen flags = 0b0000...1001 = 9u32
        // what the settings should be = 0b0000...0001 = 1u32
        let is_initialized_and_not_frozen: u32 = toggle_settings_status & 9u32;
        assert_eq(is_initialized_and_not_frozen, 1u32);

        general_settings.set(3u8, base_uri.data0); // Base URI for NFT
        general_settings.set(4u8, base_uri.data1);
        general_settings.set(5u8, base_uri.data2);
        general_settings.set(6u8, base_uri.data3);
    }

    // call this function to toggle minting, the whitelist requirement, or to permanently freeze the contract
    transition update_toggle_settings(
        public toggle_settings_bitstring: u32
    ) {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return then finalize(hash_caller, toggle_settings_bitstring);
    }

    finalize update_toggle_settings(
        public hash_caller: u128,
        public toggle_settings_bitstring: u32
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(7u8));
        // Ensure collection is initialized and not frozen.
        let toggle_settings_status: u32 = toggle_settings.get(0u8);
        // initialized & frozen flags = 0b0000...1001 = 9u32
        // what the settings should be = 0b0000...0001 = 1u32
        let is_initialized_and_not_frozen: u32 = toggle_settings_status & 9u32;
        assert_eq(is_initialized_and_not_frozen, 1u32);

        // Ensure updated settings are not uninitializing the collection.
        let still_initialized: u32 = toggle_settings_bitstring & 1u32;
        assert_eq(still_initialized, 1u32);

        toggle_settings.set(0u8, toggle_settings_bitstring);
    }

    // register a top level domain
    // only admin can call this function
    transition register_tld(
        registrar: address,
        tld: [u128; 4]
    ) {
        let name_hash: field = calc_name_hash(tld, 0field);
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return then finalize(hash_caller, registrar, name_hash, tld);
    }

    finalize register_tld(
        hash_caller: u128,
        registrar: address,
        name_hash: field,
        name: [u128; 4]
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(7u8));
        let name_struct: NameStruct = NameStruct {
            name: name,
            parent: 0field,
            resolver: 0u128
        };
        names.set(name_hash, name_struct);
        nft_owners.set(name_hash, registrar);
    }

    // register a sub domain
    // the self.caller must be the holder of parent ANS name, it can be a program or an account
    transition register(
        name: [u128; 4],
        parent: field,
        receiver: address,
        resolver: u128
    ) -> NFT {
        // Validate the name before registration
        assert(validate_name(name));
        let name_hash: field = calc_name_hash(name, parent);
        let nft: NFT = NFT {
            owner: receiver,
            data: name_hash,
            edition: 0scalar
        };
        return nft then finalize(name_hash, name, parent, resolver, self.caller);
    }

    // Register subdomain of a name
    // The parent domain must public, and the caller must be the owner of the parent domain
    finalize register(
        name_hash: field,
        name: [u128; 4],
        parent: field,
        resolver: u128,
        caller: address
    ) {
        // Check if the caller is the owner of the parent name
        // For first level domain, the caller should be the registrar program
        assert_eq(caller, nft_owners.get(parent));
        // Check if the name has already been registered
        assert_eq(names.contains(name_hash), false);

        // Ensure mint block height is less than current block height
        let mint_block: u32 = toggle_settings.get(1u8);
        let passed_height_check: bool = mint_block <= block.height;
        assert_eq(passed_height_check, true);

        // Ensure minting is allowed, and is initialized,
        let toggle_settings_status: u32 = toggle_settings.get(0u8);
        // the settings should be minting & initialized = 0b0000...0011 = 3u32
        let collection_settings_met: u32 = toggle_settings_status & 3u32;
        assert_eq(collection_settings_met, 3u32);

        let name_struct: NameStruct = NameStruct {
            name: name,
            parent: parent,
            resolver: resolver
        };

        names.set(name_hash, name_struct);
    }

    transition register_private(
        name: [u128; 4],
        parent: NFT,
        receiver: address,
        resolver: u128
    ) -> (NFT, NFT) {
        // Validate the name before registration
        assert(validate_name(name));
        let name_hash: field = calc_name_hash(name, parent.data);
        let nft: NFT = NFT {
            owner: receiver,
            data: name_hash,
            edition: 0scalar
        };
        let new_parent: NFT = NFT {
            owner: parent.owner,
            data: parent.data,
            edition: parent.edition
        };
        return (nft, new_parent) then finalize(name_hash, name, parent.data, resolver);
    }

    // Register subdomain of a name
    finalize register_private(
        name_hash: field,
        name: [u128; 4],
        parent: field,
        resolver: u128
    ) {
        // Check if the name has already been registered
        assert_eq(names.contains(name_hash), false);

        // Ensure mint block height is less than current block height
        let mint_block: u32 = toggle_settings.get(1u8);
        let passed_height_check: bool = mint_block <= block.height;
        assert_eq(passed_height_check, true);

        // Ensure minting is allowed, and is initialized,
        let toggle_settings_status: u32 = toggle_settings.get(0u8);
        // the settings should be minting & initialized = 0b0000...0011 = 3u32
        let collection_settings_met: u32 = toggle_settings_status & 3u32;
        assert_eq(collection_settings_met, 3u32);

        let name_struct: NameStruct = NameStruct {
            name: name,
            parent: parent,
            resolver: resolver
        };

        names.set(name_hash, name_struct);
    }

    // the difference between register_public and register is that register_public does not require the caller to be the owner of the parent name
    // instead, the signer must be the owner of the parent name
    // that means, the owner of the parent name must be an account not a program
    // a program can call register_public to register a subname of a domain owned by an account
    transition register_public(
        name: [u128; 4],
        parent: field,
        receiver: address,
        resolver: u128
    ) -> NFT {
        // Validate the name before registration
        assert(validate_name(name));
        let name_hash: field = calc_name_hash(name, parent);
        let nft: NFT = NFT {
            owner: receiver,
            data: name_hash,
            edition: 0scalar
        };
        return nft then finalize(name_hash, name, parent, resolver, self.signer);
    }

    // Register subdomain of a name
    // The parent domain must public, and the caller must be the owner of the parent domain
    finalize register_public(
        name_hash: field,
        name: [u128; 4],
        parent: field,
        resolver: u128,
        caller: address
    ) {
        // Check if the caller is the owner of the parent name
        // For first level domain, the caller should be the registrar program
        assert_eq(caller, nft_owners.get(parent));
        // Check if the name has already been registered
        assert_eq(names.contains(name_hash), false);

        // Ensure mint block height is less than current block height
        let mint_block: u32 = toggle_settings.get(1u8);
        let passed_height_check: bool = mint_block <= block.height;
        assert_eq(passed_height_check, true);

        // Ensure minting is allowed, and is initialized,
        let toggle_settings_status: u32 = toggle_settings.get(0u8);
        // the settings should be minting & initialized = 0b0000...0011 = 3u32
        let collection_settings_met: u32 = toggle_settings_status & 3u32;
        assert_eq(collection_settings_met, 3u32);

        let name_struct: NameStruct = NameStruct {
            name: name,
            parent: parent,
            resolver: resolver
        };

        names.set(name_hash, name_struct);
    }

    transition transfer_private(
        nft: NFT,
        private receiver: address
    ) -> NFT
    {
        return NFT {
            owner: receiver,
            data: nft.data,
            edition: 0scalar
        };
    }

    transition transfer_public(
        private receiver: address,
        private name_hash: field
    )
    {
        return then finalize(receiver, name_hash, self.caller);
    }

    finalize transfer_public(
        receiver: address,
        name_hash: field,
        caller: address
    )
    {
        assert_neq(caller, receiver);
        // check if the caller is the owner of the name or approved by the owner
        let owner: address = nft_owners.get(name_hash);
        let name_address_pair: NameAddressPair = NameAddressPair {
            name_hash: name_hash,
            nft_owner: owner
        };
        let address_pair: AddressPair = AddressPair {
            nft_owner: owner,
            nft_operator: caller
        };

        // Since this is a public name, this operation will not disclose any additional information.
        assert(caller == owner ||
           approved_for_nft.get_or_use(name_address_pair, owner) == caller ||
           approved_for_all.get_or_use(address_pair, false));

        nft_owners.set(name_hash, receiver);
        // increase the version of the name, so all resolvers will be expired
        let version: u64 = name_versions.get_or_use(name_hash, 1u64);
        name_versions.set(name_hash, version + 1u64);
        // remove the primary name if the name is the primary name of the owner
        let primary_name: field = primary_names.get_or_use(owner, 0field);
        if (primary_name == name_hash) {
            primary_names.remove(owner);
        }
    }

    transition convert_private_to_public(
        nft: NFT,
        private receiver: address
    )
    {
        return then finalize(receiver, nft.data);
    }

    finalize convert_private_to_public(
        public owner: address,
        public name_hash: field
    )
    {
        nft_owners.set(name_hash, owner);
    }

    transition convert_public_to_private(
        private name_hash: field,
        private receiver: address
    ) -> NFT
    {
        return NFT {
            owner: receiver,
            data: name_hash,
            edition: 0scalar
        } then finalize(self.caller, name_hash);
    }

    finalize convert_public_to_private(
        public caller: address,
        public name_hash: field
    )
    {
        // check if the caller is the owner of the name or approved by the owner
        let owner: address = nft_owners.get(name_hash);
        let name_address_pair: NameAddressPair = NameAddressPair {
            name_hash: name_hash,
            nft_owner: owner
        };
        let address_pair: AddressPair = AddressPair {
            nft_owner: owner,
            nft_operator: caller
        };
        // Since this is a public name, this operation will not disclose any additional information.
        assert(caller == owner ||
           approved_for_nft.get_or_use(name_address_pair, owner) == caller ||
           approved_for_all.get_or_use(address_pair, false));

        nft_owners.remove(name_hash);
        // increase the version of the name, so all resolvers will be expired
        let version: u64 = name_versions.get_or_use(name_hash, 1u64);
        name_versions.set(name_hash, version + 1u64);
        // remove the primary name if the name is the primary name of the owner
        let primary_name: field = primary_names.get_or_use(owner, 0field);
        if (primary_name == name_hash) {
            primary_names.remove(owner);
        }
    }

    transition set_primary_name(
        name_hash: field
    ) {
        return then finalize(name_hash, self.caller);
    }

    finalize set_primary_name(
        name_hash: field,
        owner: address
    ) {
        assert_eq(owner, nft_owners.get(name_hash));
        primary_names.set(owner, name_hash);
    }

    transition unset_primary_name() {
        return then finalize(self.caller);
    }

    finalize unset_primary_name(
        owner: address
    ) {
        primary_names.remove(owner);
    }

    // set resolver
    // this will update the resolver of the name in names mapping
    transition set_resolver(
        name_hash: field,
        resolver: u128
    ) {
        return then finalize(name_hash, self.caller, resolver);
    }

    finalize set_resolver(
        name_hash: field,
        owner: address,
        resolver: u128
    ){
        assert_eq(owner, nft_owners.get(name_hash));
        let name_struct: NameStruct = names.get(name_hash);
        let new_name_struct: NameStruct = NameStruct {
            name: name_struct.name,
            parent: name_struct.parent,
            resolver: resolver
        };
        names.set(name_hash, new_name_struct);
    }

    // set resolver record
    // category is the bits of the category string, u128 can store max of 16 characters
    // for example, "btc" is 6517858u128, "eth" is 6845541u128, "twitter" is 32199698188695412u128
    transition set_resolver_record(
        name_hash: field,
        category: u128,
        content: [u128; 8]
    ) {
        assert(category > 0u128);
        // ensure the content is not empty
        assert(content[0u8] > 0u128);
        return then finalize(name_hash, self.caller, category, content);
    }

    finalize set_resolver_record(
        name_hash: field,
        owner: address,
        category: u128,
        content: [u128; 8]
    ) {
        assert_eq(owner, nft_owners.get(name_hash));
        let version: u64 = name_versions.get_or_use(name_hash, 1u64);
        let resolver_index: ResolverIndex = ResolverIndex {
            name: name_hash,
            category: category,
            version: version
        };
        resolvers.set(resolver_index, content);
    }

    transition unset_resolver_record(
        name_hash: field,
        category: u128
    ) {
        return then finalize(name_hash, self.caller, category);
    }

    // increase the version of the resolver, so the resolver record will be expired
    finalize unset_resolver_record(
        name_hash: field,
        owner: address,
        category: u128
    ) {
        assert_eq(owner, nft_owners.get(name_hash));
        let version: u64 = name_versions.get_or_use(name_hash, 1u64);
        let resolver_index: ResolverIndex = ResolverIndex {
            name: name_hash,
            category: category,
            version: version
        };
        resolvers.remove(resolver_index);
    }

    transition clear_resolver_record(
        name_hash: field
    ) {
        return then finalize(name_hash, self.caller);
    }

    // increase the version of the name, so all resolvers will be expired
    finalize clear_resolver_record(
        name_hash: field,
        owner: address
    ) {
        assert_eq(owner, nft_owners.get(name_hash));
        let version: u64 = name_versions.get_or_use(name_hash, 1u64);
        name_versions.set(name_hash, version + 1u64);
    }

    // check if the name is owned by the address
    // this transition is use by other programs to check if the name is owned by the owner address
    transition is_owner(
        name_hash: field,
        owner: address
    ) {
        return then finalize(name_hash, owner);
    }

    finalize is_owner(
        name_hash: field,
        owner: address
    ) {
        assert_eq(owner, nft_owners.get(name_hash));
    }

    // Proof that you own an nft without revealing the nft.
    // this never actually destroys the nft as the finalize
    // block is guaranteed to fail.
    transition proof_ownership(
        nft: NFT,
        receiver: address
    ) -> (NFT, NFT_ownership)
    {
        let nft_ownership: NFT_ownership = NFT_ownership {
            owner: receiver,
            nft_owner: nft.owner,
            data: nft.data,
            edition: nft.edition
        };
        let new_nft: NFT = NFT {
            owner: nft.owner,
            data: nft.data,
            edition: nft.edition
        };
        return (new_nft, nft_ownership);
    }

    // Proof that you own an nft without revealing the nft.
    // this never actually destroys the nft as the finalize
    // block is guaranteed to fail.
    transition authorize(
        nft: NFT
    ) {
        return then finalize();
    }

    finalize authorize() {
        // fails on purpose, so that the nft is not burned.
        assert_eq(0u8, 1u8);
    }

    // this will actually destroys the nft
    transition burn(
        nft: NFT
    ) {
        return then finalize(nft.data);
    }

    finalize burn(name_hash: field) {
        names.remove(name_hash);
    }

    transition is_available(
        name_hash: field
    ) -> bool {
        return then finalize(name_hash);
    }

    finalize is_available(name_hash: field) {
        assert_eq(names.contains(name_hash), false);
    }

    // Approves another address to transfer the given public name_hash The zero address indicates there is no approved address.
    // There can only be one approved address per name at a given time.
    // Can only be called by the name owner
    transition approve(
        to: address,
        name_hash: field
    ) {
        return then finalize(self.caller, to, name_hash);
    }

    finalize approve(
        owner: address,
        to: address,
        name_hash: field
    ) {
        assert_eq(owner, nft_owners.get(name_hash));
        approved_for_nft.set(NameAddressPair {
            name_hash: name_hash,
            nft_owner: owner
        }, to);
    }

    // Sets or unsets the approval of a given operator An operator is allowed to transfer all public names of the sender on their behalf.
    transition set_approval_for_all(
        operator: address,
        approved: bool
    ) {
        return then finalize(self.caller, operator, approved);
    }

    finalize set_approval_for_all(
        owner: address,
        operator: address,
        approved: bool
    ) {
        approved_for_all.set(AddressPair {
            nft_owner: owner,
            nft_operator: operator
        }, approved);
    }

}
