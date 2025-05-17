import credits.aleo;
import ans_coupon_card.aleo;
import aleo_name_service_registry.aleo;

program ans_registrar_usd2.aleo {
    const ADMIN_ADDR: address = aleo1ans8gd200s2yyrx72y7txgee5snq6v6la8wa3r8r0ups4l2hjv9qku8k6k;
    const ADMIN: u8 = 0u8;
    const MINTING_FLAG: u8 = 2u8;
    const COUPON_USE_FLAG: u8 = 3u8;
    const STAKE_GAP: u8 = 4u8;
    const MIN_STAKE_PALEO: u8 = 5u8;
    const MAX_TIMESTAMP_DELAY: u8 = 6u8;

    struct UnitPriceData {
        price: u64,
        timestamp: u64
    }

    mapping general_settings: u8 => u128;
    // key is timestamp
    // key = 0u64, store the latest unit price
    mapping price_data: u64 => UnitPriceData;

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

    function calc_price(length: u8, usd_price: u64) -> u64 {
        // Calculate price in USD then convert to credits
        if (length == 5u8) {
            return 4000000000000u64 / usd_price;
        }
        if (length == 4u8) {
            return 40000000000000u64 / usd_price;
        }
        if (length == 3u8) {
            return 160000000000000u64 / usd_price;
        }
        if (length == 2u8) {
            return 640000000000000u64 / usd_price;
        }
        return 9999000000000000u64 / usd_price;
    }

    async transition initialize_registrar() -> Future {
        let admin: u128 = BHP256::hash_to_u128(ADMIN_ADDR);
        return finalize_initialize_registrar(admin);
    }

    async function finalize_initialize_registrar(
        admin: u128
    ) {
        // Ensure initialize cannot be called twice!
        let is_initialized: u128 = general_settings.get_or_use(ADMIN, 0u128);
        assert_eq(is_initialized, 0u128);

        general_settings.set(ADMIN, admin);
        general_settings.set(MINTING_FLAG, 1u128);
        general_settings.set(COUPON_USE_FLAG, 1u128);
        general_settings.set(STAKE_GAP, 1_000_000u128);
        general_settings.set(MIN_STAKE_PALEO, 10_000_000u128);
        // Set max timestamp delay to 4 hours
        general_settings.set(MAX_TIMESTAMP_DELAY, 14_400u128);
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

    async transition set_unit_price(
        public price: u64,
        public timestamp: u64
    ) -> Future {
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        let unit_price_data: UnitPriceData = UnitPriceData {
            price: price,
            timestamp: timestamp
        };
        return finalize_set_unit_price(hash_caller, unit_price_data);
    }

    async function finalize_set_unit_price(
        hash_caller: u128,
        unit_price_data: UnitPriceData,
    ) {
        // check admin
        assert_eq(hash_caller, general_settings.get(ADMIN));
        price_data.set(0u64, unit_price_data);
        price_data.set(unit_price_data.timestamp, unit_price_data);
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
        card: ans_coupon_card.aleo/CouponCard
    ) -> Future {
        assert_eq(card.discount_percent, 0u8);
        assert(card.tld == parent || card.tld == 0field);
        let length: u8 = get_name_length(name);
        assert(length >= card.limit_name_length);
        let (n, f): (aleo_name_service_registry.aleo/NFT, Future) = aleo_name_service_registry.aleo/register(name, parent, receiver, 0field);
        ans_coupon_card.aleo/use(card);
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
        pay_record: credits.aleo/credits,
        timestamp: u64,
        usd_price: u64
    ) -> Future{
        let length: u8 = get_name_length(name);
        // calc price
        let price: u64 = calc_price(length, usd_price);
        // this program address receive credits
        let (r, f): (credits.aleo/credits, Future) = credits.aleo/transfer_private_to_public(pay_record, ans_registrar_usd.aleo, price);
        let (n, f2): (aleo_name_service_registry.aleo/NFT, Future) = aleo_name_service_registry.aleo/register(name, parent, receiver, 0field);
        return finalize_register_fld(f, f2, timestamp, usd_price);
    }

    async function finalize_register_fld(
        f: Future,
        f2: Future,
        timestamp: u64,
        usd_price: u64
    ) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(MINTING_FLAG), 1u128);
        let latest_price_data: UnitPriceData = price_data.get(0u64);
        let timed_price_data: UnitPriceData = price_data.get_or_use(timestamp, latest_price_data);
        assert_eq(timed_price_data.price, usd_price);
        // check latest timestamp - timestamp <= MAX_TIMESTAMP_DELAY
        assert(latest_price_data.timestamp - timed_price_data.timestamp <= general_settings.get(MAX_TIMESTAMP_DELAY) as u64);
    }

    // register a first level domain with public credits
    async transition register_fld_public(
        name: [u128; 4],
        parent: field,
        receiver: address,
        timestamp: u64,
        usd_price: u64
    ) -> Future {
        let length: u8 = get_name_length(name);
        // calc price
        let price: u64 = calc_price(length, usd_price);
        // this program address receive credits
        let f: Future = credits.aleo/transfer_public_as_signer(ans_registrar_usd.aleo, price);
        let (n, f2): (aleo_name_service_registry.aleo/NFT, Future) = aleo_name_service_registry.aleo/register(name, parent, receiver, 0field);
        return finalize_register_fld_public(f, f2, timestamp, usd_price);
    }

    async function finalize_register_fld_public(
        f: Future,
        f2: Future,
        timestamp: u64,
        usd_price: u64
    ) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(MINTING_FLAG), 1u128);
        let latest_price_data: UnitPriceData = price_data.get(0u64);
        let timed_price_data: UnitPriceData = price_data.get_or_use(timestamp, latest_price_data);
        assert_eq(timed_price_data.price, usd_price);
        // check latest timestamp - timestamp <= MAX_TIMESTAMP_DELAY
        assert(latest_price_data.timestamp - timed_price_data.timestamp <= general_settings.get(MAX_TIMESTAMP_DELAY) as u64);
    }

    // register with coupon card
    async transition register_fld_with_coupon(
        name: [u128; 4],
        parent: field,
        receiver: address,
        pay_record: credits.aleo/credits,
        card: ans_coupon_card.aleo/CouponCard,
        timestamp: u64,
        usd_price: u64
    ) -> Future {
        assert(card.tld == parent || card.tld == 0field);
        let length: u8 = get_name_length(name);
        assert(length >= card.limit_name_length);
        // calc price
        let price: u64 = calc_price(length, usd_price);
        // discount
        price = price * card.discount_percent as u64 / 100u64;
        // this program address receive credits
        let (r, f): (credits.aleo/credits, Future) = credits.aleo/transfer_private_to_public(pay_record, ans_registrar_usd.aleo, price);
        let (n, f2): (aleo_name_service_registry.aleo/NFT, Future) = aleo_name_service_registry.aleo/register(name, parent, receiver, 0field);
        ans_coupon_card.aleo/use(card);
        return finalize_register_fld_coupon(f, f2, timestamp, usd_price);
    }

    async function finalize_register_fld_coupon(
        f: Future,
        f2: Future,
        timestamp: u64,
        usd_price: u64
    ) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(COUPON_USE_FLAG), 1u128);
        let latest_price_data: UnitPriceData = price_data.get(0u64);
        let timed_price_data: UnitPriceData = price_data.get_or_use(timestamp, latest_price_data);
        assert_eq(timed_price_data.price, usd_price);
        // check latest timestamp - timestamp <= MAX_TIMESTAMP_DELAY
        assert(latest_price_data.timestamp - timed_price_data.timestamp <= general_settings.get(MAX_TIMESTAMP_DELAY) as u64);
    }

    // register with coupon card
    async transition register_fld_with_coupon_public(
        name: [u128; 4],
        parent: field,
        receiver: address,
        card: ans_coupon_card.aleo/CouponCard,
        timestamp: u64,
        usd_price: u64
    ) -> Future {
        assert(card.tld == parent || card.tld == 0field);
        let length: u8 = get_name_length(name);
        assert(length >= card.limit_name_length);
        // calc price
        let price: u64 = calc_price(length, usd_price);
        // discount
        price = price * card.discount_percent as u64 / 100u64;
        // this program address receive credits
        let f: Future = credits.aleo/transfer_public_as_signer(ans_registrar_usd.aleo, price);
        let (n, f2): (aleo_name_service_registry.aleo/NFT, Future) = aleo_name_service_registry.aleo/register(name, parent, receiver, 0field);
        ans_coupon_card.aleo/use(card);
        return finalize_register_fld_coup_pub(f, f2, timestamp, usd_price);
    }

    async function finalize_register_fld_coup_pub(
        f: Future,
        f2: Future,
        timestamp: u64,
        usd_price: u64
    ) {
        f.await();
        f2.await();
        // check minting flag
        assert_eq(general_settings.get(COUPON_USE_FLAG), 1u128);
        let latest_price_data: UnitPriceData = price_data.get(0u64);
        let timed_price_data: UnitPriceData = price_data.get_or_use(timestamp, latest_price_data);
        assert_eq(timed_price_data.price, usd_price);
        // check latest timestamp - timestamp <= MAX_TIMESTAMP_DELAY
        assert(latest_price_data.timestamp - timed_price_data.timestamp <= general_settings.get(MAX_TIMESTAMP_DELAY) as u64);
    }

    // ADMIN FUNCTIONS
    async transition transfer_public(
        nft_data: data,
        nft_edition: scalar,
        receiver: address
    ) -> Future {
        let (nft, f): (aleo_name_service_registry.aleo/NFTView, Future) = aleo_name_service_registry.aleo/transfer_public(nft_data, nft_edition, receiver);
        let hash_caller: u128 = BHP256::hash_to_u128(self.caller);
        return finalize_transfer_public(hash_caller, f);
    }

    async function finalize_transfer_public(hash_caller: u128, f: Future) {
        f.await();
        assert_eq(hash_caller, general_settings.get(ADMIN));
    }
}
