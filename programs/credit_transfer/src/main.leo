// The 'credit_transfer' program.
import credits.aleo;
import aleo_name_service_registry.aleo;
import multi_token_support_programv1.aleo;
import pondo_core_protocolv1.aleo;

program ans_credit_transfer.aleo {
    const PALEO_TOKEN_ID: field = 1751493913335802797273486270793650302076377624243810059080883537084141842600field;

    const ADMIN: u8 = 0u8;
    const INITIALIZED: u8 = 1u8;
    const TOTAL_CREDITS: u8 = 2u8;
    const TOTAL_PALEO: u8 = 3u8;

    struct NameTokenPair {
        name_hash: field,
        token_id: field
    }
    // domain name holding amount
    mapping domain_credits: field => u64;
    // domain name holding arc21 token amount
    mapping domain_tokens: field => u128;
    // 0: admin, 1: total credits, 3. total paleo
    mapping general_settings: u8 => u128;

    async transition initialize() -> Future {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return finalize_initialize(hash_caller);
    }

    async function finalize_initialize(
        admin: u128
    ) {
        // Ensure initialize cannot be called twice!
        let is_initialized: u128 = general_settings.get_or_use(INITIALIZED, 0u128);
        assert_eq(is_initialized, 0u128);

        general_settings.set(ADMIN, admin);
        general_settings.set(INITIALIZED, 1u128);
        general_settings.set(TOTAL_CREDITS, 0u128);
        general_settings.set(TOTAL_PALEO, 0u128);
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
        assert_eq(hash_caller, general_settings.get(ADMIN));
        general_settings.set(ADMIN, new_admin); // Admin hash address
    }

    // transfer credits to an ans domain
    async transition transfer_credits (
        receiver: field, // name_hash of the ans domain
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u64,
        pay_record: credits.aleo/credits
    ) -> Future {
        let (r, f): (credits.aleo/credits, Future) = credits.aleo/transfer_private_to_public(pay_record, self.address, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_secret_hash: field = BHP256::commit_to_field(receiver, salt);
        return finalize_transfer_credits(f, name_secret_hash, amount);
    }

    async function finalize_transfer_credits(f: Future, name_secret_hash: field, amount: u64) {
        f.await();
        let current_amount: u64 = domain_credits.get_or_use(name_secret_hash, 0u64);
        domain_credits.set(name_secret_hash, current_amount + amount);
        let total_credits: u128 = general_settings.get(TOTAL_CREDITS);
        general_settings.set(TOTAL_CREDITS, total_credits + amount as u128);
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
        return finalize_transfer_credits_public(f, name_secret_hash, amount);
    }

    async function finalize_transfer_credits_public(
        f: Future,
        name_secret_hash: field,
        amount: u64
    ) {
        f.await();
        let current_amount: u64 = domain_credits.get_or_use(name_secret_hash, 0u64);
        domain_credits.set(name_secret_hash, current_amount + amount);
        let total_credits: u128 = general_settings.get(TOTAL_CREDITS);
        general_settings.set(TOTAL_CREDITS, total_credits + amount as u128);
    }

    // claim the credits with private ans domain NFT and secret
    async transition claim_credits_private (
        nft: aleo_name_service_registry.aleo/NFT,
        secret: [u128; 2], // the secret, 0-64 length ascii bits
        amount: u64
    ) -> Future {
        let (r, f): (credits.aleo/credits, Future) = credits.aleo/transfer_public_to_private(self.caller, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_secret_hash: field = BHP256::commit_to_field(nft.data.metadata[0u8], salt);
        return finalize_claim_credits_private(f, name_secret_hash, amount);
    }

    async function finalize_claim_credits_private(
        f: Future,
        name_secret_hash: field,
        amount: u64
    ) {
        f.await();
        let current_amount: u64 = domain_credits.get(name_secret_hash);
        domain_credits.set(name_secret_hash, current_amount - amount);
        let total_credits: u128 = general_settings.get(TOTAL_CREDITS);
        general_settings.set(TOTAL_CREDITS, total_credits - amount as u128);
    }

    // claim the credits with public ans domain and secret
    async transition claim_credits_public (
        name_hash: field,
        secret: [u128; 2], // the secret, 0-64 length ascii bits
        amount: u64
    ) -> Future {
        let (r, f): (credits.aleo/credits, Future) = credits.aleo/transfer_public_to_private(self.caller, amount);
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
        let ans_owner: address = aleo_name_service_registry.aleo/nft_owners.get(name_hash);
        assert_eq(owner, ans_owner);
        let current_amount: u64 = domain_credits.get(name_secret_hash);
        domain_credits.set(name_secret_hash, current_amount - amount);
        let total_credits: u128 = general_settings.get(TOTAL_CREDITS);
        general_settings.set(TOTAL_CREDITS, total_credits - amount as u128);
    }

    // transfer arc21 token to an ans domain
    async transition transfer_token (
        token_id: field, // the token id
        receiver: field, // name_hash of the ans domain
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u128,
        pay_record: multi_token_support_program.aleo/Token
    ) -> Future {
        let (r, f): (multi_token_support_program.aleo/Token, Future) = multi_token_support_program.aleo/transfer_private_to_public(self.address, amount, pay_record);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_token_pair: NameTokenPair = NameTokenPair {
            name_hash: receiver,
            token_id: token_id
        };
        let name_secret_hash: field = BHP256::commit_to_field(name_token_pair, salt);
        return finalize_transfer_token(f, token_id, name_secret_hash, amount);
    }

    async function finalize_transfer_token(
        f: Future,
        token_id: field,
        name_secret_hash: field,
        amount: u128
    ) {
        f.await();
        let current_amount: u128 = domain_tokens.get_or_use(name_secret_hash, 0u128);
        domain_tokens.set(name_secret_hash, current_amount + amount);
        if token_id == PALEO_TOKEN_ID {
            let total_paleo: u128 = general_settings.get(TOTAL_PALEO);
            general_settings.set(TOTAL_PALEO, total_paleo + amount);
        }
    }

    // transfer arc21 token to an ans domain use public balance
    async transition transfer_token_public (
        token_id: field, // the token id
        receiver: field, // name_hash of the ans domain
        secret: [u128; 2], // the secret, 0-32 length ascii bits
        amount: u128
    ) -> Future {
        let f: Future = multi_token_support_program.aleo/transfer_public_as_signer(token_id, self.address, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_token_pair: NameTokenPair = NameTokenPair {
            name_hash: receiver,
            token_id: token_id
        };
        let name_secret_hash: field = BHP256::commit_to_field(name_token_pair, salt);
        return finalize_transfer_token_public(f, token_id, name_secret_hash, amount);
    }

    async function finalize_transfer_token_public(
        f: Future,
        token_id: field,
        name_secret_hash: field,
        amount: u128
    ) {
        f.await();
        let current_amount: u128 = domain_tokens.get_or_use(name_secret_hash, 0u128);
        domain_tokens.set(name_secret_hash, current_amount + amount);
        if token_id == PALEO_TOKEN_ID {
            let total_paleo: u128 = general_settings.get(TOTAL_PALEO);
            general_settings.set(TOTAL_PALEO, total_paleo + amount);
        }
    }

    // claim the arc21 token with private ans domain NFT and secret
    async transition claim_token_private (
        token_id: field, // the token id
        nft: aleo_name_service_registry.aleo/NFT,
        secret: [u128; 2], // the secret, 0-64 length ascii bits
        amount: u128,
        external_authorization_required: bool
    ) -> Future {
        let (r, f): (multi_token_support_program.aleo/Token, Future) = multi_token_support_program.aleo/transfer_public_to_private(token_id, self.caller, amount, external_authorization_required);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_token_pair: NameTokenPair = NameTokenPair {
            name_hash: nft.data.metadata[0u8],
            token_id: token_id
        };
        let name_secret_hash: field = BHP256::commit_to_field(name_token_pair, salt);
        return finalize_claim_token_private(f, token_id, name_secret_hash, amount);
    }

    async function finalize_claim_token_private(
        f: Future,
        token_id: field,
        name_secret_hash: field,
        amount: u128
    ) {
        f.await();
        let current_amount: u128 = domain_tokens.get(name_secret_hash);
        domain_tokens.set(name_secret_hash, current_amount - amount);
        if token_id == PALEO_TOKEN_ID {
            let total_paleo: u128 = general_settings.get(TOTAL_PALEO);
            general_settings.set(TOTAL_PALEO, total_paleo - amount);
        }
    }

    // claim the arc21 token with public ans domain and secret
    async transition claim_token_public (
        token_id: field, // the token id
        name_hash: field,
        secret: [u128; 2], // the secret, 0-64 length ascii bits
        amount: u128,
        external_authorization_required: bool
    ) -> Future {
        let (r, f): (multi_token_support_program.aleo/Token, Future) = multi_token_support_program.aleo/transfer_public_to_private(token_id, self.caller, amount, external_authorization_required);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_token_pair: NameTokenPair = NameTokenPair {
            name_hash: name_hash,
            token_id: token_id
        };
        let name_secret_hash: field = BHP256::commit_to_field(name_token_pair, salt);
        return finalize_claim_token_public(f, token_id, name_hash, self.caller, name_secret_hash, amount);
    }

    async function finalize_claim_token_public(
        f: Future,
        token_id: field,
        name_hash: field,
        owner: address,
        name_secret_hash: field,
        amount: u128
    ) {
        f.await();
        let ans_owner: address = aleo_name_service_registry.aleo/nft_owners.get(name_hash);
        assert_eq(owner, ans_owner);
        let current_amount: u128 = domain_tokens.get(name_secret_hash);
        domain_tokens.set(name_secret_hash, current_amount - amount);
        if token_id == PALEO_TOKEN_ID {
            let total_paleo: u128 = general_settings.get(TOTAL_PALEO);
            general_settings.set(TOTAL_PALEO, total_paleo - amount);
        }
    }

    // Stake to Pondo Core Protocol
    async transition stake(
        credit_amount: u64,
        paleo_amount: u64
    ) -> Future {
        // Transfer the credits to signer
        let f0: Future = credits.aleo/transfer_public(self.signer, credit_amount);
        // Deposit the credits into the pondo core protocol
        let f1: Future = pondo_core_protocolv1.aleo/deposit_public_as_signer(credit_amount, paleo_amount, self.address);
        // Transfer the pAleo to current program
        let f2: Future = multi_token_support_programv1.aleo/transfer_public_as_signer(PALEO_TOKEN_ID, self.address, paleo_amount as u128);
        return finalize_stake(f0, f1, f2);
    }

    async function finalize_stake(f0: Future, f1: Future, f2: Future) {
        f0.await();
        f1.await();
        f2.await();
    }
}
