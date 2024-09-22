// The 'ans_resolver' program.
import aleo_name_service_registry_v4.aleo;

program ans_resolver_v4.aleo {
    // Structure holding a name_hash and its type
    struct ResolverIndex {
        name: field, // The name_hash
        category: u128, // The type of the resolver, can contain 16 characters in maximum
        version: u64 // The version of the name
    }

    // Mapping from a ResolverIndex structure to an Name array(string), max 128 ASCII characters
    mapping resolvers: ResolverIndex => [u128; 8];

    function calc_name_hash_for_data(nft_data: data) -> field {
        let data_hash: field = BHP256::hash_to_field(nft_data);
        let name_hash: field = BHP256::commit_to_field(data_hash, 0scalar);
        return name_hash;
    }

    // set resolver record when ANS is private
    // category is the bits of the category string, u128 can store max of 16 characters
    // for example, "btc" is 6517858u128, "eth" is 6845541u128, "twitter" is 32199698188695412u128
    async transition set_resolver_record(
        nft: aleo_name_service_registry_v4.aleo/NFT,
        category: u128,
        content: [u128; 8]
    ) -> Future {
        assert(category > 0u128);
        // ensure the content is not empty
        assert(content[0u8] > 0u128);
        let name_hash: field = calc_name_hash_for_data(nft.data);
        let new_nft: aleo_name_service_registry_v4.aleo/NFT = aleo_name_service_registry_v4.aleo/check(nft);
        return finalize_set_resolver_record(name_hash, category, content);
    }

    async function finalize_set_resolver_record(
        name_hash: field,
        category: u128,
        content: [u128; 8]
    ) {
        let version: u64 = aleo_name_service_registry_v4.aleo/name_versions.get_or_use(name_hash, 1u64);
        let resolver_index: ResolverIndex = ResolverIndex {
            name: name_hash,
            category: category,
            version: version
        };
        resolvers.set(resolver_index, content);
    }

    async transition unset_resolver_record(
        nft: aleo_name_service_registry_v4.aleo/NFT,
        category: u128
    ) -> Future {
        let name_hash: field = calc_name_hash_for_data(nft.data);
        let new_nft: aleo_name_service_registry_v4.aleo/NFT = aleo_name_service_registry_v4.aleo/check(nft);
        return finalize_unset_resolver_record(name_hash, category);
    }

    // increase the version of the resolver, so the resolver record will be expired
    async function finalize_unset_resolver_record(
        name_hash: field,
        category: u128
    ) {
        let version: u64 = aleo_name_service_registry_v4.aleo/name_versions.get_or_use(name_hash, 1u64);
        let resolver_index: ResolverIndex = ResolverIndex {
            name: name_hash,
            category: category,
            version: version
        };
        resolvers.remove(resolver_index);
    }

    // set resolver record when ANS is public
    // category is the bits of the category string, u128 can store max of 16 characters
    // for example, "btc" is 6517858u128, "eth" is 6845541u128, "twitter" is 32199698188695412u128
    async transition set_resolver_record_public(
        name_hash: field,
        category: u128,
        content: [u128; 8]
    ) -> Future {
        assert(category > 0u128);
        // ensure the content is not empty
        assert(content[0u8] > 0u128);
        return finalize_set_resolver_record_public(name_hash, category, content, self.caller);
    }

    async function finalize_set_resolver_record_public(
        name_hash: field,
        category: u128,
        content: [u128; 8],
        owner: address,
    ) {
        assert_eq(owner, aleo_name_service_registry_v4.aleo/nft_owners.get(name_hash));
        let version: u64 = aleo_name_service_registry_v4.aleo/name_versions.get_or_use(name_hash, 1u64);
        let resolver_index: ResolverIndex = ResolverIndex {
            name: name_hash,
            category: category,
            version: version
        };
        resolvers.set(resolver_index, content);
    }

    async transition unset_resolver_record_public(
        name_hash: field,
        category: u128
    ) -> Future {
        return finalize_unset_resolver_record_public(name_hash, category, self.caller);
    }

    // increase the version of the resolver, so the resolver record will be expired
    async function finalize_unset_resolver_record_public(
        name_hash: field,
        category: u128,
        owner: address,
    ) {
        assert_eq(owner, aleo_name_service_registry_v4.aleo/nft_owners.get(name_hash));
        let version: u64 = aleo_name_service_registry_v4.aleo/name_versions.get_or_use(name_hash, 1u64);
        let resolver_index: ResolverIndex = ResolverIndex {
            name: name_hash,
            category: category,
            version: version
        };
        resolvers.remove(resolver_index);
    }
}
