// The 'program' program.
program aleo_name_service_registry_v2.aleo {
    record NFT {
        owner: address,
        data: field,  // this is the name_hash of the name
        edition: scalar
    }

    // register a sub domain
    // the self.caller must be the holder of parent ANS name, it can be a program or an account
    transition register(
        name: [u128; 4],
        parent: field,
        receiver: address,
        resolver: u128
    ) -> NFT {
        let name_hash: field = 0field;
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
        assert(true);
    }

    transition register_private(
        name: [u128; 4],
        parent: NFT,
        receiver: address,
        resolver: u128
    ) -> (NFT, NFT) {
        let name_hash: field = 0field;
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
        assert(true);
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
        let name_hash: field = 0field;
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
        assert(true);
    }
}
