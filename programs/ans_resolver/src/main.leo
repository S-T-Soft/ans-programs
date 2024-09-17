// The 'ans_resolver' program.
import aleo_name_service_registry_v2.aleo;

program ans_resolver_v2.aleo {
    // Structure holding a name_hash and its type
    struct ResolverIndex {
        name: field, // The name_hash
        category: u128, // The type of the resolver, can contain 16 characters in maximum
        version: u64 // The version of the name
    }

    // Mapping from a ResolverIndex structure to an Name array(string), max 128 ASCII characters
    mapping resolvers: ResolverIndex => [u128; 8];

    // set resolver record
    // category is the bits of the category string, u128 can store max of 16 characters
    // for example, "btc" is 6517858u128, "eth" is 6845541u128, "twitter" is 32199698188695412u128
    async transition set_resolver_record(
        name_hash: field,
        category: u128,
        content: [u128; 8]
    ) -> Future {
        assert(category > 0u128);
        // ensure the content is not empty
        assert(content[0u8] > 0u128);
        return finalize_set_resolver_record(name_hash, self.caller, category, content);
    }

    async function finalize_set_resolver_record(
        name_hash: field,
        owner: address,
        category: u128,
        content: [u128; 8]
    ) {
        assert_eq(owner, aleo_name_service_registry_v2.aleo/nft_owners.get(name_hash));
        let version: u64 = aleo_name_service_registry_v2.aleo/name_versions.get_or_use(name_hash, 1u64);
        let resolver_index: ResolverIndex = ResolverIndex {
            name: name_hash,
            category: category,
            version: version
        };
        resolvers.set(resolver_index, content);
    }

    async transition unset_resolver_record(
        name_hash: field,
        category: u128
    ) -> Future{
        return finalize_unset_resolver_record(name_hash, self.caller, category);
    }

    // increase the version of the resolver, so the resolver record will be expired
    async function finalize_unset_resolver_record(
        name_hash: field,
        owner: address,
        category: u128
    ) {
        assert_eq(owner, aleo_name_service_registry_v2.aleo/nft_owners.get(name_hash));
        let version: u64 = aleo_name_service_registry_v2.aleo/name_versions.get_or_use(name_hash, 1u64);
        let resolver_index: ResolverIndex = ResolverIndex {
            name: name_hash,
            category: category,
            version: version
        };
        resolvers.remove(resolver_index);
    }
}
