// The 'credit_transfer' program.
import credits.aleo;
import aleo_name_service_registry_v4.aleo;
import multi_token_support_programv1.aleo;

program ans_credit_transfer_v1.aleo {
    struct NameTokenPair {
        name_hash: field,
        token_id: field
    }
    // domain name holding amount
    mapping domain_credits: field => u64;
    // domain name holding arc21 token amount
    mapping domain_tokens: field => u128;

    struct data {
        metadata: [field; 4], // the first element is the name_hash of the name
    }

    inline calc_name_hash_for_data(nft_data: data) -> field {
        let data_hash: field = BHP256::hash_to_field(nft_data);
        let name_hash: field = BHP256::commit_to_field(data_hash, 0scalar);
        return name_hash;
    }

    // transfer credits to an ans domain
    async transition transfer_credits (
        receiver: field, // name_hash of the ans domain
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u64,
        pay_record: credits.aleo/credits
    ) -> (credits.aleo/credits, Future) {
        let (r, f): (credits.aleo/credits, Future) = credits.aleo/transfer_private_to_public(pay_record, self.address, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_secret_hash: field = BHP256::commit_to_field(receiver, salt);
        return (r, finalize_transfer_credits(f, name_secret_hash, amount));
    }

    async function finalize_transfer_credits(
        f: Future,
        name_secret_hash: field,
        amount: u64
    ) {
        f.await();
        let current_amount: u64 = domain_credits.get_or_use(name_secret_hash, 0u64);
        domain_credits.set(name_secret_hash, current_amount + amount);
    }

    // transfer credits to an ans domain use public balance
    async transition transfer_credits_public (
        receiver: field, // name_hash of the ans domain
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u64
    ) -> Future {
        let f: Future = credits.aleo/transfer_public_as_signer(self.address, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_secret_hash: field = BHP256::commit_to_field(receiver, salt);
        return finalize_transfer_credits_pub(f, name_secret_hash, amount);
    }

    async function finalize_transfer_credits_pub(
        f: Future,
        name_secret_hash: field,
        amount: u64
    ) {
        f.await();
        let current_amount: u64 = domain_credits.get_or_use(name_secret_hash, 0u64);
        domain_credits.set(name_secret_hash, current_amount + amount);
    }

    // claim the credits with private ans domain NFT and secret
    async transition claim_credits_private (
        receiver: address,
        nft: aleo_name_service_registry_v4.aleo/NFT,
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u64
    ) -> (credits.aleo/credits, Future) {
        let (r, f): (credits.aleo/credits, Future) = credits.aleo/transfer_public_to_private(receiver, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let new_nft: aleo_name_service_registry_v4.aleo/NFT = aleo_name_service_registry_v4.aleo/check(nft);
        let name_secret_hash: field = BHP256::commit_to_field(calc_name_hash_for_data(nft.data), salt);
        return (r, finalize_claim_credits_private(f, name_secret_hash, amount));
    }

    async function finalize_claim_credits_private(
        f: Future,
        name_secret_hash: field,
        amount: u64
    ) {
        f.await();
        let current_amount: u64 = domain_credits.get(name_secret_hash);
        domain_credits.set(name_secret_hash, current_amount - amount);
    }

    // claim the credits with public ans domain and secret, ensure the caller is the owner
    async transition claim_credits_public (
        receiver: address,
        name_hash: field,
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u64
    ) -> Future {
        let f: Future = credits.aleo/transfer_public(receiver, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_secret_hash: field = BHP256::commit_to_field(name_hash, salt);
        return finalize_claim_credits_public(f, name_hash, self.caller, name_secret_hash, amount);
    }

    async function finalize_claim_credits_public(
        f: Future,
        name_hash: field,
        owner: address,
        name_secret_hash: field,
        amount: u64
    ) {
        f.await();
        let ans_owner: address = aleo_name_service_registry_v4.aleo/nft_owners.get(name_hash);
        assert_eq(owner, ans_owner);
        let current_amount: u64 = domain_credits.get(name_secret_hash);
        domain_credits.set(name_secret_hash, current_amount - amount);
    }

    // claim the credits with public ans domain and secret, ensure the signer is the owner
    async transition claim_credits_as_signer (
        receiver: address,
        name_hash: field,
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u64
    ) -> Future {
        let f: Future = credits.aleo/transfer_public(receiver, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_secret_hash: field = BHP256::commit_to_field(name_hash, salt);
        return finalize_claim_credits_signer(f, name_hash, self.signer, name_secret_hash, amount);
    }

    async function finalize_claim_credits_signer(
        f: Future,
        name_hash: field,
        owner: address,
        name_secret_hash: field,
        amount: u64
    ) {
        f.await();
        let ans_owner: address = aleo_name_service_registry_v4.aleo/nft_owners.get(name_hash);
        assert_eq(owner, ans_owner);
        let current_amount: u64 = domain_credits.get(name_secret_hash);
        domain_credits.set(name_secret_hash, current_amount - amount);
    }

    // transfer arc21 token to an ans domain
    async transition transfer_token (
        token_id: field, // the token id
        receiver: field, // name_hash of the ans domain
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u128,
        pay_record: multi_token_support_programv1.aleo/Token
    ) -> (multi_token_support_programv1.aleo/Token, Future) {
        let (r, f): (multi_token_support_programv1.aleo/Token, Future) = multi_token_support_programv1.aleo/transfer_private_to_public(self.address, amount, pay_record);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_token_pair: NameTokenPair = NameTokenPair {
            name_hash: receiver,
            token_id: token_id
        };
        let name_secret_hash: field = BHP256::commit_to_field(name_token_pair, salt);
        return (r, finalize_transfer_token(f, name_secret_hash, amount));
    }

    async function finalize_transfer_token(
        f: Future,
        name_secret_hash: field,
        amount: u128
    ) {
        f.await();
        let current_amount: u128 = domain_tokens.get_or_use(name_secret_hash, 0u128);
        domain_tokens.set(name_secret_hash, current_amount + amount);
    }

    // transfer arc21 token to an ans domain use public balance
    async transition transfer_token_public (
        token_id: field, // the token id
        receiver: field, // name_hash of the ans domain
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u128
    ) -> Future {
        let f: Future = multi_token_support_programv1.aleo/transfer_public_as_signer(token_id, self.address, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_token_pair: NameTokenPair = NameTokenPair {
            name_hash: receiver,
            token_id: token_id
        };
        let name_secret_hash: field = BHP256::commit_to_field(name_token_pair, salt);
        return finalize_transfer_token_public(f, name_secret_hash, amount);
    }

    async function finalize_transfer_token_public(
        f: Future,
        name_secret_hash: field,
        amount: u128
    ) {
        f.await();
        let current_amount: u128 = domain_tokens.get_or_use(name_secret_hash, 0u128);
        domain_tokens.set(name_secret_hash, current_amount + amount);
    }

    // claim the arc21 token with private ans domain NFT and secret
    async transition claim_token_private (
        receiver: address,
        token_id: field, // the token id
        nft: aleo_name_service_registry_v4.aleo/NFT,
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u128,
        external_authorization_required: bool
    ) -> (multi_token_support_programv1.aleo/Token, Future) {
        let (r, f): (multi_token_support_programv1.aleo/Token, Future) = multi_token_support_programv1.aleo/transfer_public_to_private(token_id, receiver, amount, external_authorization_required);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let new_nft: aleo_name_service_registry_v4.aleo/NFT = aleo_name_service_registry_v4.aleo/check(nft);
        let name_token_pair: NameTokenPair = NameTokenPair {
            name_hash: calc_name_hash_for_data(nft.data),
            token_id: token_id
        };
        let name_secret_hash: field = BHP256::commit_to_field(name_token_pair, salt);
        return (r, finalize_claim_token_private(f, name_secret_hash, amount));
    }

    async function finalize_claim_token_private(
        f: Future,
        name_secret_hash: field,
        amount: u128
    ) {
        f.await();
        let current_amount: u128 = domain_tokens.get(name_secret_hash);
        domain_tokens.set(name_secret_hash, current_amount - amount);
    }

    // claim the arc21 token with public ans domain and secret, ensure the caller is the owner
    async transition claim_token_public (
        receiver: address,
        token_id: field, // the token id
        name_hash: field,
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u128
    ) -> Future {
        let f: Future = multi_token_support_programv1.aleo/transfer_public(token_id, receiver, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_token_pair: NameTokenPair = NameTokenPair {
            name_hash: name_hash,
            token_id: token_id
        };
        let name_secret_hash: field = BHP256::commit_to_field(name_token_pair, salt);
        return finalize_claim_token_public(f, name_hash, self.caller, name_secret_hash, amount);
    }

    async function finalize_claim_token_public(
        f: Future,
        name_hash: field,
        owner: address,
        name_secret_hash: field,
        amount: u128
    ) {
        f.await();
        let ans_owner: address = aleo_name_service_registry_v4.aleo/nft_owners.get(name_hash);
        assert_eq(owner, ans_owner);
        let current_amount: u128 = domain_tokens.get(name_secret_hash);
        domain_tokens.set(name_secret_hash, current_amount - amount);
    }

    // claim the arc21 token with public ans domain and secret, ensure the signer is the owner
    async transition claim_token_as_signer (
        receiver: address,
        token_id: field, // the token id
        name_hash: field,
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u128
    ) -> Future {
        let f: Future = multi_token_support_programv1.aleo/transfer_public(token_id, receiver, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_token_pair: NameTokenPair = NameTokenPair {
            name_hash: name_hash,
            token_id: token_id
        };
        let name_secret_hash: field = BHP256::commit_to_field(name_token_pair, salt);
        return finalize_claim_token_signer(f, name_hash, self.signer, name_secret_hash, amount);
    }

    async function finalize_claim_token_signer(
        f: Future,
        name_hash: field,
        owner: address,
        name_secret_hash: field,
        amount: u128
    ) {
        f.await();
        let ans_owner: address = aleo_name_service_registry_v4.aleo/nft_owners.get(name_hash);
        assert_eq(owner, ans_owner);
        let current_amount: u128 = domain_tokens.get(name_secret_hash);
        domain_tokens.set(name_secret_hash, current_amount - amount);
    }
}
