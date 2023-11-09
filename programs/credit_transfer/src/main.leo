// The 'credit_transfer' program.
import credits.leo;
import aleo_name_service_registry_v1.leo;

program ans_credit_transfer_v1.aleo {
    // domain name holding amount
    mapping domain_credits: field => u64;

    // transfer credits to an ans domain
    transition transfer_credits (
        receiver: field, // name_hash of the ans domain
        secret: [u128; 4], // the secret, 0-64 length ascii bits
        amount: u64,
        pay_record: credits.leo/credits
    ) {
        let program_address: address = aleo1jvpk02xw8kp9cl48km49n0er8rr9fkamyph9yxsnynl7ufgx2y9q7qvqfg;
        credits.leo/transfer_private_to_public(pay_record, program_address, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_secret_hash: field = BHP256::commit_to_field(receiver, salt);
        return then finalize(name_secret_hash, amount);
    }

    finalize transfer_credits(name_secret_hash: field, amount: u64) {
        let current_amount: u64 = domain_credits.get_or_use(name_secret_hash, 0u64);
        domain_credits.set(name_secret_hash, current_amount + amount);
    }

    // claim the credits with private ans domain NFT and secret
    transition claim_credits_private (
        nft: aleo_name_service_registry_v1.leo/NFT,
        secret: [u128; 4], // the secret, 0-64 length ascii bits
        amount: u64
    ) {
        credits.leo/transfer_public_to_private(self.caller, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_secret_hash: field = BHP256::commit_to_field(nft.data, salt);
        return then finalize(name_secret_hash, amount);
    }

    finalize claim_credits_private(
        name_secret_hash: field,
        amount: u64
    ) {
        let current_amount: u64 = domain_credits.get(name_secret_hash);
        assert_eq(current_amount >= amount, true);
        domain_credits.set(name_secret_hash, current_amount - amount);
    }

    // claim the credits with public ans domain and secret
    transition claim_credits_public (
        name_hash: field,
        secret: [u128; 4], // the secret, 0-64 length ascii bits
        amount: u64
    ) {
        aleo_name_service_registry_v1.leo/check_ownship(name_hash, self.caller);
        credits.leo/transfer_public_to_private(self.caller, amount);
        let salt: scalar = Poseidon2::hash_to_scalar(secret);
        let name_secret_hash: field = BHP256::commit_to_field(name_hash, salt);
        return then finalize(name_hash, name_secret_hash, amount);
    }

    finalize claim_credits_public(
        name_hash: field,
        name_secret_hash: field,
        amount: u64
    ) {
        let current_amount: u64 = domain_credits.get(name_secret_hash);
        assert(current_amount >= amount);
        domain_credits.set(name_secret_hash, current_amount - amount);
    }
}
