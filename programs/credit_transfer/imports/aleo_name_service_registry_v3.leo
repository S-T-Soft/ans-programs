// The 'program' program.
program aleo_name_service_registry_v3.aleo {
    record NFT {
        owner: address,
        data: field,  // this is the name_hash of the name
        edition: scalar
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
        assert(true);
    }

}
