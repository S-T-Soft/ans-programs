import credits.aleo;
import ans_coupon_card_v1.aleo;
import aleo_name_service_registry_v1.aleo;

program ans_registrar_v1.aleo {
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

    async transition initialize_registrar() -> Future{
        let admin: u128 = BHP256::hash_to_u128(self.caller);
        return finalize_initialize_registrar(admin);
    }

    async function finalize_initialize_registrar(
        admin: u128
    ) {
        general_settings.set(0u8, admin);
    }

    async transition set_minting_flag(
        flag: u128,
        cc_flag: u128
    ) -> Future {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return finalize_set_minting_flag(hash_caller, flag, cc_flag);
    }

    async function finalize_set_minting_flag(
        hash_caller: u128,
        flag: u128,
        cc_flag: u128
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(0u8));
        general_settings.set(1u8, flag);
        general_settings.set(2u8, cc_flag);
    }

    async transition change_admin(
        private admin: address
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
        assert_eq(hash_caller, general_settings.get(0u8));
        general_settings.set(7u8, new_admin); // Admin hash address
    }

    // register with coupon card
    async transition register_free(
        name: [u128; 4],
        parent: field,
        receiver: address,
        card: ans_coupon_card_v1.aleo/CouponCard
    ) -> Future {
        assert_eq(card.discount_percent, 0u8);
        assert(card.tld == parent || card.tld == 0field);
        let length: u8 = get_name_length(name);
        assert(length >= card.limit_name_length);
        let (n, f): (aleo_name_service_registry_v1.aleo/NFT, Future) = aleo_name_service_registry_v1.aleo/register(name, parent, receiver, 0u128);
        ans_coupon_card_v1.aleo/use(card);
        return finalize_register_free(f);
    }

    async function finalize_register_free(f: Future) {
        f.await();
        // check minting flag
        assert_eq(general_settings.get(2u8), 1u128);
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
        let (n, f2): (aleo_name_service_registry_v1.aleo/NFT, Future) = aleo_name_service_registry_v1.aleo/register(name, parent, receiver, 0u128);
        return finalize_register_fld(f, f2);
    }

    async function finalize_register_fld(f: Future, f2: Future) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(1u8), 1u128);
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
        let (n, f2): (aleo_name_service_registry_v1.aleo/NFT, Future) = aleo_name_service_registry_v1.aleo/register(name, parent, receiver, 0u128);
        return finalize_register_fld_public(f, f2);
    }

    async function finalize_register_fld_public(f: Future, f2: Future) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(1u8), 1u128);
    }

    // register with coupon card
    async transition register_fld_with_coupon(
        name: [u128; 4],
        parent: field,
        receiver: address,
        pay_record: credits.aleo/credits,
        card: ans_coupon_card_v1.aleo/CouponCard
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
        let (n, f2): (aleo_name_service_registry_v1.aleo/NFT, Future) = aleo_name_service_registry_v1.aleo/register(name, parent, receiver, 0u128);
        ans_coupon_card_v1.aleo/use(card);
        return finalize_register_fld_with_coupon(f, f2);
    }

    async function finalize_register_fld_with_coupon(f: Future, f2: Future) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(2u8), 1u128);
    }

    // register with coupon card
    async transition register_fld_with_coupon_public(
        name: [u128; 4],
        parent: field,
        receiver: address,
        card: ans_coupon_card_v1.aleo/CouponCard
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
        let (n, f2): (aleo_name_service_registry_v1.aleo/NFT, Future) = aleo_name_service_registry_v1.aleo/register(name, parent, receiver, 0u128);
        ans_coupon_card_v1.aleo/use(card);
        return finalize_register_fld_with_coupon_public(f, f2);
    }

    async function finalize_register_fld_with_coupon_public(f: Future, f2: Future) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(2u8), 1u128);
    }

    async transition stake(validator: address, withdrawal: address, amount: u64) -> Future {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        let f: Future = credits.aleo/bond_public(validator, withdrawal, amount);
        return finalize_stake(f, hash_caller);
    }

    async function finalize_stake(f: Future, hash_caller: u128) {
        f.await();
        // check admin
        assert_eq(hash_caller, general_settings.get(0u8));
    }
}
