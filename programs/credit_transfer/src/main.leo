// The 'credit_transfer' program.
import credits.aleo;
import aleo_name_service_registry_v1.aleo;

program ans_credit_transfer_v1.aleo {
    // domain name holding amount
    mapping domain_credits: field => u64;

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
    }

    // claim the credits with private ans domain NFT and secret
    async transition claim_credits_private (
        nft: aleo_name_service_registry_v1.aleo/NFT,
        secret: [u128; 2], // the secret, 0-64 length ascii bits
        amount: u64
    ) -> Future {
        let (r, f): (credits.aleo/credits, Future) = credits.aleo/transfer_public_to_private(self.caller, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_secret_hash: field = BHP256::commit_to_field(nft.data, salt);
        return finalize_claim_credits_private(f, name_secret_hash, amount);
    }

    async function finalize_claim_credits_private(
        f: Future,
        name_secret_hash: field,
        amount: u64
    ) {
        f.await();
        let current_amount: u64 = domain_credits.get(name_secret_hash);
        assert_eq(current_amount >= amount, true);
        domain_credits.set(name_secret_hash, current_amount - amount);
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
        let ans_owner: address = aleo_name_service_registry_v1.aleo/nft_owners.get(name_hash);
        assert_eq(owner, ans_owner);
        let current_amount: u64 = domain_credits.get(name_secret_hash);
        assert(current_amount >= amount);
        domain_credits.set(name_secret_hash, current_amount - amount);
    }
}
