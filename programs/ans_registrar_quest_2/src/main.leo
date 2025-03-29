import aleo_name_service_registry_v4.aleo;
import ans_resolver_v4.aleo;
import messenger.aleo;

program ans_registrar_quest_2.aleo {
    const ADMIN_ADDR: address = aleo1sr8d93usu395zc29qcl35ul2e7hl2538hl8pehe4ms88q4g70gxq3ffw0v;

    async transition transfer_private_to_public(
        nft: aleo_name_service_registry_v4.aleo/NFT,
        private receiver: address,
        memo: [field; 8]
    ) -> Future {
        let (n, f): (aleo_name_service_registry_v4.aleo/NFTView, Future) = aleo_name_service_registry_v4.aleo/transfer_private_to_public(nft, receiver);
        messenger.aleo/send(ADMIN_ADDR, memo);
        return transfer_private_to_public_f(f);
    }

    async function transfer_private_to_public_f(f: Future) {
        f.await();
    }

    async transition set_resolver_record(
        nft: aleo_name_service_registry_v4.aleo/NFT,
        category: u128,
        content: [u128; 8],
        memo: [field; 8]
    ) -> Future {
        let f: Future = ans_resolver_v4.aleo/set_resolver_record(nft, category, content);
        messenger.aleo/send(ADMIN_ADDR, memo);
        return set_resolver_record_f(f);
    }

    async function set_resolver_record_f(f: Future) {
        f.await();
    }
}
