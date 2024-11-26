// The 'register' program.
import ans_utils_v2.aleo;

program aleo_name_service_registry_v4.aleo {
    const ADMIN_ADDR: address = aleo1sr8d93usu395zc29qcl35ul2e7hl2538hl8pehe4ms88q4g70gxq3ffw0v;
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
        resolver: field // the resolver program, 0 means default resolver program
    }

    struct ANSAllowance {
        account: address,  // the owner of the ANS
        spender: address,  // the operator of the ANS
    }

    struct data {
        metadata: [field; 4], // the first element is the name_hash of the name
    }

    record NFT {
        owner: address,
        data: data,
        edition: scalar
    }

    record NFTView {
        owner: address,
        data: data,
        edition: scalar,
        is_view: bool
    }

    // Mappings for different data structures
    // Store public domain to address
    // For top level domains, the address is the registrar
    mapping nft_owners: field => address;
    // Mapping from a field(hash name) to an NameStruct structure
    mapping names: field => NameStruct;
    // Mapping from an address to a primary name
    mapping primary_names: address => field;
    // Mapping from a name_hash to a version number, version plus one when the name is transferred or burned
    mapping name_versions: field => u64;

    // nft_owner approved operators to transfer nft
    mapping for_all_allowances: field => bool;
    // nft_owner approved address to transfer nft
    mapping allowances: field => field;

    mapping general_settings: u8 => field;
    mapping toggle_settings: u8 => u32;

    inline calc_name_field(name: [u128; 4], parent: field) -> field {
        let full_name: Name = Name {
            name: name,
            parent: parent
        };
        return Poseidon2::hash_to_field(full_name);
    }

    inline calc_name_hash_for_data(nft_data: data) -> field {
        let data_hash: field = BHP256::hash_to_field(nft_data);
        let name_hash: field = BHP256::commit_to_field(data_hash, 0scalar);
        return name_hash;
    }

    inline calc_name_hash_for_field(name_field: field) -> field {
        let nft_data: data = data {
            metadata: [name_field, 0field, 0field, 0field],
        };
        return calc_name_hash_for_data(nft_data);
    }

    // Calculate the name hash, return the name field and the name hash
    function calc_name_hash(name: [u128; 4], parent: field) -> (field, field) {
        let name_field: field = calc_name_field(name, parent);
        let name_hash: field = calc_name_hash_for_field(name_field);
        return (name_field, name_hash);
    }

    async transition initialize_collection(
        public base_uri: [field; 4],
    ) -> Future {
        return finalize_initialize_collection(base_uri);
    }

    async function finalize_initialize_collection(
        public base_uri: [field; 4],
    ) {
        // Ensure initialize cannot be called twice!
        let toggle_settings_status: u32 = toggle_settings.get_or_use(0u8, 0u32);
        let is_initialized: u32 = toggle_settings_status & 1u32;
        assert_eq(is_initialized, 0u32);

        general_settings.set(0u8, 1000000000field); // This setting is for the Leo wallet, no real effect on the contract
        general_settings.set(1u8, 1000000000field); // This setting is for the Leo wallet, no real effect on the contract
        general_settings.set(2u8, 4279891field); // Symbol for the NFT "ANS"
        general_settings.set(3u8, base_uri[0u8]); // Base URI for NFT
        general_settings.set(4u8, base_uri[1u8]);
        general_settings.set(5u8, base_uri[2u8]);
        general_settings.set(6u8, base_uri[3u8]);
        general_settings.set(7u8, ADMIN_ADDR as field); // Admin hash address
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
        return finalize_set_admin(self.caller as field, admin as field);
    }

    async function finalize_set_admin(
        public caller: field,
        public new_admin: field
    ) {
        // check admin
        assert_eq(caller, general_settings.get(7u8));
        general_settings.set(7u8, new_admin); // Admin hash address
    }

    async transition update_settings(
        key: u8,
        value: field
    ) -> Future {
        assert_neq(key, 0u8);
        assert_neq(key, 1u8);
        assert_neq(key, 7u8);
        return finalize_update_settings(self.caller as field, key, value);
    }

    async function finalize_update_settings(
        public caller: field,
        public key: u8,
        public value: field
    ) {
        // check admin
        assert_eq(caller, general_settings.get(7u8));
        // Ensure collection is initialized and not frozen.
        let toggle_settings_status: u32 = toggle_settings.get(0u8);
        // initialized & frozen flags = 0b0000...1001 = 9u32
        // what the settings should be = 0b0000...0001 = 1u32
        let is_initialized_and_not_frozen: u32 = toggle_settings_status & 9u32;
        assert_eq(is_initialized_and_not_frozen, 1u32);

        general_settings.set(key, value);
    }

    // call this function to toggle minting, the whitelist requirement, or to permanently freeze the contract
    async transition update_toggle_settings(
        public toggle_settings_bitstring: u32
    ) -> Future {
        return finalize_update_toggle_settings(self.caller as field, toggle_settings_bitstring);
    }

    async function finalize_update_toggle_settings(
        public caller: field,
        public toggle_settings_bitstring: u32
    ) {
        // check admin
        assert_eq(caller, general_settings.get(7u8));
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
        let (name_field, name_hash): (field, field) = calc_name_hash(tld, 0field);
        let name_struct: NameStruct = NameStruct {
            name: tld,
            parent: 0field,
            resolver: 0field
        };
        return finalize_register_tld(self.caller as field, registrar, name_hash, name_struct);
    }

    async function finalize_register_tld(
        caller: field,
        registrar: address,
        name_hash: field,
        name_struct: NameStruct
    ) {
        // check admin
        assert_eq(caller, general_settings.get(7u8));
        // Check if the name has already been registered
        assert_eq(names.contains(name_hash), false);
        names.set(name_hash, name_struct);
        nft_owners.set(name_hash, registrar);
    }

    // register a sub domain
    // the self.caller must be the holder of parent ANS name, it can be a program or an account
    async transition register(
        name: [u128; 4],
        parent: field,
        receiver: address,
        resolver: field
    ) -> (NFT, Future) {
        // Validate the name before registration
        assert(ans_utils_v2.aleo/validate_name(name));
        let (name_field, name_hash): (field, field) = calc_name_hash(name, parent);
        let nft_data: data = data {
            metadata: [name_field, 0field, 0field, 0field]
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
        resolver: field,
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
        resolver: field
    ) -> (NFT, NFT, Future) {
        // Validate the name before registration
        assert(ans_utils_v2.aleo/validate_name(name));
        let parent_name_hash: field = calc_name_hash_for_data(parent.data);
        let (name_field, name_hash): (field, field) = calc_name_hash(name, parent_name_hash);
        let nft_data: data = data {
            metadata: [name_field, 0field, 0field, 0field]
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
        resolver: field
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
        resolver: field
    ) -> (NFT, Future) {
        // Validate the name before registration
        assert(ans_utils_v2.aleo/validate_name(name));
        let (name_field, name_hash): (field, field) = calc_name_hash(name, parent);
        let nft_data: data = data {
            metadata: [name_field, 0field, 0field, 0field]
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
        resolver: field,
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

    async transition transfer_private(
        nft: NFT,
        private receiver: address
    ) -> (NFT, Future)
    {
        let name_hash: field = calc_name_hash_for_data(nft.data);
        let new_nft: NFT = NFT {
            owner: receiver,
            data: nft.data,
            edition: 0scalar
        };
        return (new_nft, finalize_transfer_private(name_hash));
    }

    async function finalize_transfer_private(
        public name_hash: field
    ) {
        // increase the version of the name, so all resolvers will be expired
        let version: u64 = name_versions.get_or_use(name_hash, 1u64);
        name_versions.set(name_hash, version + 1u64);
    }

    async transition transfer_public(
        private nft_data: data,
        private nft_edition: scalar,
        public receiver: address
    ) -> (NFTView, Future) {
        let name_hash: field = calc_name_hash_for_data(nft_data);
        let nft_view: NFTView = NFTView {
            owner: receiver,
            data: nft_data,
            edition: 0scalar,
            is_view: true,
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
        allowances.remove(name_hash);
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
        let name_hash: field = calc_name_hash_for_data(nft.data);

        let nft_view: NFTView = NFTView {
            owner: receiver,
            data: nft.data,
            edition: 0scalar,
            is_view: true,
        };
        let transfer_private_to_public_future: Future =
            transfer_private_to_pub(
                receiver, name_hash
            );
        return (
            nft_view,
            transfer_private_to_public_future
        );
    }

    async function transfer_private_to_pub(
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
        let name_hash: field = calc_name_hash_for_data(nft_data);
        let nft: NFT = NFT {
            owner: receiver,
            data: nft_data,
            edition: 0scalar
        };
        return (nft, transfer_public_to_priv(self.caller, name_hash));
    }

    async function transfer_public_to_priv(
        public caller: address,
        public name_hash: field
    ) {
        // check if the caller is the owner of the name
        let owner: address = nft_owners.get(name_hash);
        assert_eq(caller, owner);
        nft_owners.remove(name_hash);
        allowances.remove(name_hash);
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
        resolver: field
    ) -> Future {
        return finalize_set_resolver(name_hash, self.caller, resolver);
    }

    async function finalize_set_resolver(
        name_hash: field,
        owner: address,
        resolver: field
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

    // check if the ANS is owned by the caller, return a new ANS with same data
    transition check(
        nft: NFT
    ) -> NFT {
        return NFT {
            owner: nft.owner,
            data: nft.data,
            edition: 0scalar
        };
    }

    // this will actually destroys the nft
    async transition burn(
        nft: NFT
    ) -> Future {
        let name_hash: field = calc_name_hash_for_data(nft.data);
        return finalize_burn(name_hash);
    }

    async function finalize_burn(name_hash: field) {
        names.remove(name_hash);
        // increase the version of the name, so all resolvers will be expired
        let version: u64 = name_versions.get_or_use(name_hash, 1u64);
        name_versions.set(name_hash, version + 1u64);
    }

    // Approves another address to transfer the given public name_hash The zero address indicates there is no approved address.
    // There can only be one approved address per name at a given time.
    // Can only be called by the name owner
    async transition approve_public(
        private spender: address,
        private nft_data: data,
        private nft_edition: scalar,
    ) -> Future {
        let name_hash: field = calc_name_hash_for_data(nft_data);

        let apvl: ANSAllowance = ANSAllowance {
            account: self.caller,
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
        allowances.set(name_hash, apvl_hash);
    }

    // Sets or unsets the approval of a given operator An operator is allowed to transfer all public names of the sender on their behalf.
    async transition set_for_all_approval(
        spender: address,
        approved: bool
    ) -> Future {
        let apvl: ANSAllowance = ANSAllowance {
            account: self.caller,
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
        for_all_allowances.set(apvl_hash, approved);
    }

    async transition transfer_from_public(
        public from: address,
        public to: address,
        private nft_data: data,
        private nft_edition: scalar,
    ) -> (NFTView, Future) {
        let name_hash: field = calc_name_hash_for_data(nft_data);

        let nft_view: NFTView = NFTView {
            owner: to,
            data: nft_data,
            edition: 0scalar,
            is_view: true,
        };

        let apvl: ANSAllowance = ANSAllowance {
            account: from,
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
            allowances.get_or_use(name_hash, 0field) == apvl_hash
            || for_all_allowances.get_or_use(apvl_hash, false)
        );

        let owner: address = nft_owners.get(name_hash);
        assert_eq(from, owner);

        allowances.remove(name_hash);
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
