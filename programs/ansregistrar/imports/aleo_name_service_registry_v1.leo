// The 'program' program.
program aleo_name_service_registry_v1.aleo {
    struct Name {
        data1: u128, // The first 128 bits of the ASCII domain name
        data2: u128, // The next 128 bits of the ASCII domain name
        data3: u128, // The next 128 bits of the ASCII domain name
        data4: u128 // The last 128 bits of the ASCII domain name
    }

    struct TokenId {
        data1: u128, // data1 to data4 store the Name structure
        data2: u128,
        data3: u128,
        data4: u128,
        parent: field,
        resolver: u128, // the resolver progra, n0 means current program
    }

    record NFT {
        owner: address,
        data: TokenId,
        edition: scalar
    }

    transition register(
        name: Name,
        receiver: address,
        parent: field,
        resolver: u128
    ) {}

    transition register_private(
        name: Name,
        receiver: address,
        parent: NFT,
        resolver: u128
    ) {}

    transition register_public(
        name: Name,
        receiver: address,
        parent: field,
        resolver: u128
    ) {}
}
