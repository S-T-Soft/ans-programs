// The 'register' program.
import ans_utils.aleo;

program aleo_name_service_registry_v1.aleo {
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
        resolver: u128 // the resolver program, 0 means default resolver program
    }

    struct approval {
        approver: address,  // the owner of the nft
        spender: address,  // the operator of the nft
    }

    struct data {
        metadata: [field; 4], // the first element is the name_hash of the name
        content: Name
    }

    record NFT {
        owner: address,
        data: data,
        edition: scalar
    }

    record NFTView {
        owner: address,
        data: data,
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
    // Mapping from a name_hash to a version number
    mapping name_versions: field => u64;

    // nft_owner approved operators to transfer nft
    mapping for_all_approvals: field => bool;
    // nft_owner approved address to transfer nft
    mapping nft_approvals: field => field;

    mapping general_settings: u8 => u128;
    mapping toggle_settings: u8 => u32;

    function calc_name_hash(name: [u128; 4], parent: field) -> field {
        let full_name: Name = Name {
            name: name,
            parent: parent
        };
        return Poseidon2::hash_to_field(full_name);
    }

    async transition initialize_collection(
        public total: u128,
        public symbol: u128,
        public base_uri: [u128; 4],
    ) -> Future {
        // set the caller to admin
        let admin: u128 = BHP256::hash_to_u128(self.caller);
        return finalize_initialize_collection(total, symbol, admin, base_uri);
    }

    async function finalize_initialize_collection(
        public total: u128,
        public symbol: u128,
        public admin: u128,
        public base_uri: [u128; 4],
    ) {
        // Ensure initialize cannot be called twice!
        let toggle_settings_status: u32 = toggle_settings.get_or_use(0u8, 0u32);
        let is_initialized: u32 = toggle_settings_status & 1u32;
        assert_eq(is_initialized, 0u32);

        general_settings.set(0u8, total); // This setting is for the Leo wallet, no real effect on the contract
        general_settings.set(1u8, total); // This setting is for the Leo wallet, no real effect on the contract
        general_settings.set(2u8, symbol); // Symbol for the NFT
        general_settings.set(3u8, base_uri[0u8]); // Base URI for NFT
        general_settings.set(4u8, base_uri[1u8]);
        general_settings.set(5u8, base_uri[2u8]);
        general_settings.set(6u8, base_uri[3u8]);
        general_settings.set(7u8, admin); // Admin hash address
        // initialized flag = 0b0000...0001 = 1u32
        // minting flag = 0b0000...0010 = 2u32
        // frozen flag = 0b0000...1000 = 8u32
        // defaults -- not frozen, not minting, initialized
        // 0b0000...0001 = 1u32.
        toggle_settings.set(0u8, 1u32);
    }

    async transition set_admin(
        private admin: address
    ) -> Future {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        let new_admin: u128 = BHP256::hash_to_u128(admin);
        return finalize_set_admin(hash_caller, new_admin);
    }

    async function finalize_set_admin(
        public hash_caller: u128,
        public new_admin: u128
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(7u8));
        general_settings.set(7u8, new_admin); // Admin hash address
    }

    async transition update_base_uri(
        public base_uri: [u128; 4]
    ) -> Future {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return finalize_update_base_uri(hash_caller, base_uri);
    }

    async function finalize_update_base_uri(
        public hash_caller: u128,
        public base_uri: [u128; 4]
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(7u8));
        // Ensure collection is initialized and not frozen.
        let toggle_settings_status: u32 = toggle_settings.get(0u8);
        // initialized & frozen flags = 0b0000...1001 = 9u32
        // what the settings should be = 0b0000...0001 = 1u32
        let is_initialized_and_not_frozen: u32 = toggle_settings_status & 9u32;
        assert_eq(is_initialized_and_not_frozen, 1u32);

        general_settings.set(3u8, base_uri[0u8]); // Base URI for NFT
        general_settings.set(4u8, base_uri[1u8]);
        general_settings.set(5u8, base_uri[2u8]);
        general_settings.set(6u8, base_uri[3u8]);
    }

    // call this function to toggle minting, the whitelist requirement, or to permanently freeze the contract
    async transition update_toggle_settings(
        public toggle_settings_bitstring: u32
    ) -> Future {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return finalize_update_toggle_settings(hash_caller, toggle_settings_bitstring);
    }

    async function finalize_update_toggle_settings(
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
    async transition register_tld(
        registrar: address,
        tld: [u128; 4]
    ) -> Future {
        let name_hash: field = calc_name_hash(tld, 0field);
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        let name_struct: NameStruct = NameStruct {
            name: tld,
            parent: 0field,
            resolver: 0u128
        };
        return finalize_register_tld(hash_caller, registrar, name_hash, name_struct);
    }

    async function finalize_register_tld(
        hash_caller: u128,
        registrar: address,
        name_hash: field,
        name_struct: NameStruct
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(7u8));
        names.set(name_hash, name_struct);
        nft_owners.set(name_hash, registrar);
    }

    // register a sub domain
    // the self.caller must be the holder of parent ANS name, it can be a program or an account
    async transition register(
        name: [u128; 4],
        parent: field,
        receiver: address,
        resolver: u128
    ) -> (NFT, Future) {
        // Validate the name before registration
        assert(ans_utils.aleo/validate_name(name));
        let name_hash: field = calc_name_hash(name, parent);
        let nft_data: data = data {
            metadata: [name_hash, 0field, 0field, 0field],
            content: Name {
                name: name,
                parent: parent
            }
        };
        let nft: NFT = NFT {
            owner: receiver,
            data: nft_data,
            edition: 0scalar
        };
        return (nft, finalize_register(name_hash, name, parent, resolver, self.caller));
    }

    // Register subdomain of a name
    // The parent domain must public, and the caller must be the owner of the parent domain
    async function finalize_register(
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

    async transition register_private(
        name: [u128; 4],
        parent: NFT,
        receiver: address,
        resolver: u128
    ) -> (NFT, NFT, Future) {
        // Validate the name before registration
        assert(ans_utils.aleo/validate_name(name));
        let parent_name_hash: field = parent.data.metadata[0u8];
        let name_hash: field = calc_name_hash(name, parent_name_hash);
        let nft_data: data = data {
            metadata: [name_hash, 0field, 0field, 0field],
            content: Name {
                name: name,
                parent: parent_name_hash
            }
        };
        let nft: NFT = NFT {
            owner: receiver,
            data: nft_data,
            edition: 0scalar
        };
        let new_parent: NFT = NFT {
            owner: parent.owner,
            data: parent.data,
            edition: parent.edition
        };
        return (nft, new_parent, finalize_register_private(name_hash, name, parent_name_hash, resolver));
    }

    // Register subdomain of a name
    async function finalize_register_private(
        name_hash: field,
        name: [u128; 4],
        parent: field,
        resolver: u128
    ) {
        // Check if the name has already been registered
        assert_eq(names.contains(name_hash), false);

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
    async transition register_public(
        name: [u128; 4],
        parent: field,
        receiver: address,
        resolver: u128
    ) -> (NFT, Future) {
        // Validate the name before registration
        assert(ans_utils.aleo/validate_name(name));
        let name_hash: field = calc_name_hash(name, parent);
        let nft_data: data = data {
            metadata: [name_hash, 0field, 0field, 0field],
            content: Name {
                name: name,
                parent: parent
            }
        };
        let nft: NFT = NFT {
            owner: receiver,
            data: nft_data,
            edition: 0scalar
        };
        return (nft, finalize_register_public(name_hash, name, parent, resolver, self.signer));
    }

    // Register subdomain of a name
    // The parent domain must public, and the caller must be the owner of the parent domain
    async function finalize_register_public(
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

    async transition transfer_public(
        private nft_data: data,
        private nft_edition: scalar,
        public receiver: address
    ) -> (NFTView, Future) {
        let name_hash: field = nft_data.metadata[0u8];
        assert_eq(name_hash, calc_name_hash(nft_data.content.name, nft_data.content.parent));
        let nft_view: NFTView = NFTView {
            owner: receiver,
            data: nft_data,
            edition: nft_edition,
        };
        let transfer_public_future: Future = finalize_transfer_public(
             receiver, name_hash, self.caller
        );
        return (
            nft_view,
            transfer_public_future
        );
    }

    async function finalize_transfer_public(
        receiver: address,
        name_hash: field,
        caller: address
    )
    {
        // check if the caller is the owner of the name
        let owner: address = nft_owners.get(name_hash);
        assert_eq(caller, owner);

        nft_owners.set(name_hash, receiver);
        nft_approvals.remove(name_hash);
        // increase the version of the name, so all resolvers will be expired
        let version: u64 = name_versions.get_or_use(name_hash, 1u64);
        name_versions.set(name_hash, version + 1u64);
        // remove the primary name if the name is the primary name of the owner
        let primary_name: field = primary_names.get_or_use(owner, 0field);
        if (primary_name == name_hash && owner != receiver) {
            primary_names.remove(owner);
        }
    }

    async transition transfer_private_to_public(
        nft: NFT,
        private receiver: address
    ) -> (NFTView, Future) {
        let name_hash: field = nft.data.metadata[0u8];

        let nft_view: NFTView = NFTView {
            owner: receiver,
            data: nft.data,
            edition: nft.edition,
        };
        let transfer_private_to_public_future: Future =
            finalize_transfer_private_to_public(
                receiver, name_hash
            );
        return (
            nft_view,
            transfer_private_to_public_future
        );
    }

    async function finalize_transfer_private_to_public(
        public owner: address,
        public name_hash: field
    )
    {
        nft_owners.set(name_hash, owner);
    }

    async transition transfer_public_to_private(
        private nft_data: data,
        private nft_edition: scalar,
        private receiver: address,
    ) -> (NFT, Future) {
        let name_hash: field = nft_data.metadata[0u8];
        assert_eq(name_hash, calc_name_hash(nft_data.content.name, nft_data.content.parent));
        let nft: NFT = NFT {
            owner: receiver,
            data: nft_data,
            edition: 0scalar
        };
        return (nft, finalize_transfer_public_to_private(self.caller, name_hash));
    }

    async function finalize_transfer_public_to_private(
        public caller: address,
        public name_hash: field
    ) {
        // check if the caller is the owner of the name
        let owner: address = nft_owners.get(name_hash);
        assert_eq(caller, owner);
        nft_owners.remove(name_hash);
        nft_approvals.remove(name_hash);
        // increase the version of the name, so all resolvers will be expired
        let version: u64 = name_versions.get_or_use(name_hash, 1u64);
        name_versions.set(name_hash, version + 1u64);
        // remove the primary name if the name is the primary name of the owner
        let primary_name: field = primary_names.get_or_use(owner, 0field);
        if (primary_name == name_hash) {
            primary_names.remove(owner);
        }
    }

    async transition set_primary_name(
        name_hash: field
    ) -> Future {
        return finalize_set_primary_name(name_hash, self.caller);
    }

    async function finalize_set_primary_name(
        name_hash: field,
        owner: address
    ) {
        assert_eq(owner, nft_owners.get(name_hash));
        primary_names.set(owner, name_hash);
    }

    async transition unset_primary_name() -> Future {
        return finalize_unset_primary_name(self.caller);
    }

    async function finalize_unset_primary_name(
        owner: address
    ) {
        primary_names.remove(owner);
    }

    // set resolver
    // this will update the resolver of the name in names mapping
    async transition set_resolver(
        name_hash: field,
        resolver: u128
    ) -> Future {
        return finalize_set_resolver(name_hash, self.caller, resolver);
    }

    async function finalize_set_resolver(
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

    // Proof that you own an nft without revealing the nft.
    // this never actually destroys the nft as the finalize
    // block is guaranteed to fail.
    async transition authorize(
        nft: NFT
    ) -> Future {
        return finalize_authorize();
    }

    async function finalize_authorize() {
        // fails on purpose, so that the nft is not burned.
        assert_eq(0u8, 1u8);
    }

    // this will actually destroys the nft
    async transition burn(
        nft: NFT
    ) -> Future {
        return finalize_burn(nft.data.metadata[0u8]);
    }

    async function finalize_burn(name_hash: field) {
        names.remove(name_hash);
    }

    // Approves another address to transfer the given public name_hash The zero address indicates there is no approved address.
    // There can only be one approved address per name at a given time.
    // Can only be called by the name owner
    async transition approve_public(
        private spender: address,
        private nft_data: data,
        private nft_edition: scalar,
    ) -> Future {
        let name_hash: field = nft_data.metadata[0u8];
        assert_eq(name_hash, calc_name_hash(nft_data.content.name, nft_data.content.parent));

        let apvl: approval = approval {
            approver: self.caller,
            spender: spender,
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);
        return finalize_approve_public(
            self.caller, apvl_hash, name_hash,
        );
    }
    async function finalize_approve_public(
        caller: address,
        apvl_hash: field,
        name_hash: field,
    ){
        let owner: address = nft_owners.get(name_hash);
        assert_eq(owner, caller);
        nft_approvals.set(name_hash, apvl_hash);
    }

    // Sets or unsets the approval of a given operator An operator is allowed to transfer all public names of the sender on their behalf.
    async transition set_for_all_approval(
        spender: address,
        approved: bool
    ) -> Future {
        let apvl: approval = approval {
            approver: self.caller,
            spender: spender,
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);
        return finalize_set_for_all_approval(
            apvl_hash, approved
        );
    }

    async function finalize_set_for_all_approval(
        apvl_hash: field,
        approved: bool,
    ){
        for_all_approvals.set(apvl_hash, approved);
    }

    async transition transfer_from_public(
        public from: address,
        public to: address,
        private nft_data: data,
        private nft_edition: scalar,
    ) -> (NFTView, Future) {
        let name_hash: field = nft_data.metadata[0u8];
        assert_eq(name_hash, calc_name_hash(nft_data.content.name, nft_data.content.parent));

        let nft_view: NFTView = NFTView {
            owner: to,
            data: nft_data,
            edition: nft_edition,
        };

        let apvl: approval = approval {
            approver: from,
            spender: self.caller,
        };
        let apvl_hash: field = BHP256::hash_to_field(apvl);

        let transfer_from_public_future: Future =
            finalize_transfer_from_public(
                apvl_hash, from, to, name_hash
            );
        return (
            nft_view,
            transfer_from_public_future
        );
    }

    async function finalize_transfer_from_public(
        apvl_hash: field,
        from: address,
        to: address,
        name_hash: field,
    ) {
        assert(
            nft_approvals.contains(name_hash)
            || for_all_approvals.get_or_use(apvl_hash, false)
        );

        let owner: address = nft_owners.get(name_hash);
        assert_eq(from, owner);

        nft_approvals.remove(name_hash);
        nft_owners.set(name_hash, to);

        // increase the version of the name, so all resolvers will be expired
        let version: u64 = name_versions.get_or_use(name_hash, 1u64);
        name_versions.set(name_hash, version + 1u64);
        // remove the primary name if the name is the primary name of the owner
        let primary_name: field = primary_names.get_or_use(owner, 0field);
        if (primary_name == name_hash) {
            primary_names.remove(owner);
        }
    }

}
