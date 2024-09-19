import credits.aleo;
import ans_coupon_card_v2.aleo;
import aleo_name_service_registry_v3.aleo;
import pondo_core_protocolv1.aleo;

program ans_registrar_v5.aleo {
    const ADMIN: u8 = 0u8;
    const INITIALIZED: u8 = 1u8;
    const MINTING_FLAG: u8 = 2u8;
    const COUPON_USE_FLAG: u8 = 3u8;
    const STAKE_GAP: u8 = 4u8;
    const MIN_STAKE_PALEO: u8 = 5u8;

    mapping general_settings: u8 => u128;

    function get_name_length(name: [u128; 4]) -> u8 {
        let val: u128 = name[0u8];
        if (val > 4294967295u128) {
            return 5u8;
        }
        if (val > 16777215u128) {
            return 4u8;
        }
        if (val > 65535u128) {
            return 3u8;
        }
        if (val > 255u128) {
            return 2u8;
        }
        return 1u8;
    }

    function calc_price(length: u8) -> u64 {
        if (length == 5u8) {
            return 2000000u64;
        }
        if (length == 4u8) {
            return 10000000u64;
        }
        if (length == 3u8) {
            return 50000000u64;
        }
        if (length == 2u8) {
            return 250000000u64;
        }
        return 1250000000u64;
    }

    async transition initialize_registrar() -> Future {
        let admin: u128 = BHP256::hash_to_u128(self.caller);
        return finalize_initialize_registrar(admin);
    }

    async function finalize_initialize_registrar(
        admin: u128
    ) {
        // Ensure initialize cannot be called twice!
        let is_initialized: u128 = general_settings.get_or_use(INITIALIZED, 0u128);
        assert_eq(is_initialized, 0u128);

        general_settings.set(ADMIN, admin);
        general_settings.set(INITIALIZED, 1u128);
        general_settings.set(MINTING_FLAG, 0u128);
        general_settings.set(COUPON_USE_FLAG, 1u128);
        general_settings.set(STAKE_GAP, 1_000_000u128);
        general_settings.set(MIN_STAKE_PALEO, 10_000_000u128);
    }

    async transition update_setting(
        key: u8,
        value: u128,
    ) -> Future {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return finalize_update_setting(hash_caller, key, value);
    }

    async function finalize_update_setting(
        hash_caller: u128,
        key: u8,
        value: u128,
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(ADMIN));
        general_settings.set(key, value);
    }

    async transition change_admin(
        admin: address
    ) -> Future {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        let new_admin: u128 = BHP256::hash_to_u128(admin);
        return finalize_change_admin(hash_caller, new_admin);
    }

    async function finalize_change_admin(
        public hash_caller: u128,
        public new_admin: u128
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(ADMIN));
        general_settings.set(ADMIN, new_admin); // Admin hash address
    }

    // register with coupon card
    async transition register_free(
        name: [u128; 4],
        parent: field,
        receiver: address,
        card: ans_coupon_card_v2.aleo/CouponCard
    ) -> Future {
        assert_eq(card.discount_percent, 0u8);
        assert(card.tld == parent || card.tld == 0field);
        let length: u8 = get_name_length(name);
        assert(length >= card.limit_name_length);
        let (n, f): (aleo_name_service_registry_v3.aleo/NFT, Future) = aleo_name_service_registry_v3.aleo/register(name, parent, receiver, 0u128);
        ans_coupon_card_v2.aleo/use(card);
        return finalize_register_free(f);
    }

    async function finalize_register_free(f: Future) {
        f.await();
        // check minting flag
        assert_eq(general_settings.get(COUPON_USE_FLAG), 1u128);
    }

    // register a first level domain
    async transition register_fld(
        name: [u128; 4],
        parent: field,
        receiver: address,
        pay_record: credits.aleo/credits
    ) -> Future{
        let length: u8 = get_name_length(name);
        // calc price
        let price: u64 = calc_price(length);
        // this program address receive credits
        let (r, f): (credits.aleo/credits, Future) = credits.aleo/transfer_private_to_public(pay_record, self.address, price);
        let (n, f2): (aleo_name_service_registry_v3.aleo/NFT, Future) = aleo_name_service_registry_v3.aleo/register(name, parent, receiver, 0u128);
        return finalize_register_fld(f, f2);
    }

    async function finalize_register_fld(f: Future, f2: Future) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(MINTING_FLAG), 1u128);
    }

    // register a first level domain with public credits
    async transition register_fld_public(
        name: [u128; 4],
        parent: field,
        receiver: address
    ) -> Future {
        let length: u8 = get_name_length(name);
        // calc price
        let price: u64 = calc_price(length);
        // this program address receive credits
        let f: Future = credits.aleo/transfer_public_as_signer(self.address, price);
        let (n, f2): (aleo_name_service_registry_v3.aleo/NFT, Future) = aleo_name_service_registry_v3.aleo/register(name, parent, receiver, 0u128);
        return finalize_register_fld_public(f, f2);
    }

    async function finalize_register_fld_public(f: Future, f2: Future) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(MINTING_FLAG), 1u128);
    }

    // register with coupon card
    async transition register_fld_with_coupon(
        name: [u128; 4],
        parent: field,
        receiver: address,
        pay_record: credits.aleo/credits,
        card: ans_coupon_card_v2.aleo/CouponCard
    ) -> Future {
        assert(card.tld == parent || card.tld == 0field);
        let length: u8 = get_name_length(name);
        assert(length >= card.limit_name_length);
        // calc price
        let price: u64 = calc_price(length);
        // discount
        price = price * card.discount_percent as u64 / 100u64;
        // this program address receive credits
        let (r, f): (credits.aleo/credits, Future) = credits.aleo/transfer_private_to_public(pay_record, self.address, price);
        let (n, f2): (aleo_name_service_registry_v3.aleo/NFT, Future) = aleo_name_service_registry_v3.aleo/register(name, parent, receiver, 0u128);
        ans_coupon_card_v2.aleo/use(card);
        return finalize_register_fld_with_coupon(f, f2);
    }

    async function finalize_register_fld_with_coupon(f: Future, f2: Future) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(COUPON_USE_FLAG), 1u128);
    }

    // register with coupon card
    async transition register_fld_with_coupon_public(
        name: [u128; 4],
        parent: field,
        receiver: address,
        card: ans_coupon_card_v2.aleo/CouponCard
    ) -> Future {
        assert(card.tld == parent || card.tld == 0field);
        let length: u8 = get_name_length(name);
        assert(length >= card.limit_name_length);
        // calc price
        let price: u64 = calc_price(length);
        // discount
        price = price * card.discount_percent as u64 / 100u64;
        // this program address receive credits
        let f: Future = credits.aleo/transfer_public_as_signer(self.address, price);
        let (n, f2): (aleo_name_service_registry_v3.aleo/NFT, Future) = aleo_name_service_registry_v3.aleo/register(name, parent, receiver, 0u128);
        ans_coupon_card_v2.aleo/use(card);
        return finalize_register_fld_with_coupon_public(f, f2);
    }

    async function finalize_register_fld_with_coupon_public(f: Future, f2: Future) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(COUPON_USE_FLAG), 1u128);
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
        return finalize_stake(f0, f1, f2, credit_amount, paleo_amount);
    }

    async function finalize_stake(f0: Future, f1: Future, f2: Future, credit_amount: u64, paleo_amount: u64) {
        f0.await();
        f1.await();
        f2.await();

        let min_stake_paleo: u128 = general_settings.get(MIN_STAKE_PALEO);
        let paleo_amount128: u128 = paleo_amount as u128;
        assert(paleo_amount128 >= min_stake_paleo);

        let pondo_protocol_account: u64 = credits.aleo/account.get_or_use(pondo_core_protocolv1.aleo, 0u64);
        let pondo_reserved_for_withdrawal: u64 = pondo_core_protocolv1.aleo/balances.get(CLAIMABLE_WITHDRAWALS);
        let deposit_pool: u64 = pondo_protocol_account - credit_amount - pondo_reserved_for_withdrawal;

        let currently_delegated: u64 = pondo_core_protocolv1.aleo/balances.get(DELEGATED_BALANCE);
        let current_owed_commission: u64 = pondo_core_protocolv1.aleo/owed_commission.get(0u8);
        let total_paleo_pool: u64 = multi_token_support_programv1.aleo/registered_tokens.get(PALEO_TOKEN_ID).supply as u64 + current_owed_commission - paleo_amount;

        let full_balance: u64 = currently_delegated + deposit_pool;
        let paleo_for_deposit: u128 = (total_paleo_pool as u128 * credit_amount as u128) / full_balance as u128;

        // assert that the minted paleo is within stake gap pALEO of the expected amount
        let stake_gap: u128 = general_settings.get(STAKE_GAP);
        assert(paleo_for_deposit - paleo_amount128 < stake_gap);
    }

    // ADMIN FUNCTIONS
    async transition transfer_public(
        nft_data: data,
        nft_edition: scalar,
        receiver: address
    ) -> Future {
        let (nft, f): (aleo_name_service_registry_v3.aleo/NFTView, Future) = aleo_name_service_registry_v3.aleo/transfer_public(nft_data, nft_edition, receiver);
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return finalize_transfer_public(hash_caller, f);
    }

    async function finalize_transfer_public(hash_caller: u128, f: Future) {
        f.await();
        assert_eq(hash_caller, general_settings.get(ADMIN));
    }

    // Withdraw from Pondo Core Protocol
    async transition withdraw(account: address, amount: u64) -> Future {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        let f: Future = multi_token_support_programv1.aleo/transfer_public(PALEO_TOKEN_ID, account, amount as u128);
        return finalize_withdraw(f, hash_caller);
    }

    async function finalize_withdraw(f: Future, hash_caller: u128) {
        f.await();
        // check admin
        assert_eq(hash_caller, general_settings.get(ADMIN));
    }

    // copy from pondo core protocol
    const PALEO_TOKEN_ID: field = 1751493913335802797273486270793650302076377624243810059080883537084141842600field;
    const DELEGATED_BALANCE: u8 = 0u8;
    const CLAIMABLE_WITHDRAWALS: u8 = 2u8;
}
