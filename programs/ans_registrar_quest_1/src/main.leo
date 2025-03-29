import credits.aleo;
import ans_registrar_usd_v2.aleo;
import messenger.aleo;

program ans_registrar_quest_1.aleo {
    const ADMIN_ADDR: address = aleo1sr8d93usu395zc29qcl35ul2e7hl2538hl8pehe4ms88q4g70gxq3ffw0v;

    // register with coupon card
    async transition register_free(
        name: [u128; 4],
        parent: field,
        receiver: address,
        card: ans_coupon_card_v3.aleo/CouponCard,
        memo: [field; 8]
    ) -> Future {
        let f: Future = ans_registrar_usd_v2.aleo/register_free(name, parent, receiver, card);
        messenger.aleo/send(ADMIN_ADDR, memo);
        return finalize_register_free(f);
    }

    async function finalize_register_free(f: Future) {
        f.await();
    }

    // register a first level domain
    async transition register_fld(
        name: [u128; 4],
        parent: field,
        receiver: address,
        pay_record: credits.aleo/credits,
        is_sgx: bool,
        timestamp: u128,
        usd_price: u64,
        memo: [field; 8]
    ) -> Future {
        let f: Future = ans_registrar_usd_v2.aleo/register_fld(name, parent, receiver, pay_record, is_sgx, timestamp, usd_price);
        messenger.aleo/send(ADMIN_ADDR, memo);
        return finalize_register_fld(f);
    }

    async function finalize_register_fld(f: Future) {
        f.await();
    }

    // register a first level domain with public credits
    async transition register_fld_public(
        name: [u128; 4],
        parent: field,
        receiver: address,
        is_sgx: bool,
        timestamp: u128,
        usd_price: u64,
        memo: [field; 8]
    ) -> Future {
        let f: Future = ans_registrar_usd_v2.aleo/register_fld_public(name, parent, receiver, is_sgx, timestamp, usd_price);
        messenger.aleo/send(ADMIN_ADDR, memo);
        return finalize_register_fld_public(f);
    }

    async function finalize_register_fld_public(f: Future) {
        f.await();
    }

    // register with coupon card
    async transition register_fld_with_coupon(
        name: [u128; 4],
        parent: field,
        receiver: address,
        pay_record: credits.aleo/credits,
        card: ans_coupon_card_v3.aleo/CouponCard,
        is_sgx: bool,
        timestamp: u128,
        usd_price: u64,
        memo: [field; 8]
    ) -> Future {
        let f: Future = ans_registrar_usd_v2.aleo/register_fld_with_coupon(name, parent, receiver, pay_record, card, is_sgx, timestamp, usd_price);
        messenger.aleo/send(ADMIN_ADDR, memo);
        return register_fld_with_coup(f);
    }

    async function register_fld_with_coup(f: Future) {
        f.await();
    }

    // register with coupon card
    async transition register_fld_with_coupon_public(
        name: [u128; 4],
        parent: field,
        receiver: address,
        card: ans_coupon_card_v3.aleo/CouponCard,
        is_sgx: bool,
        timestamp: u128,
        usd_price: u64,
        memo: [field; 8]
    ) -> Future {
        let f: Future = ans_registrar_usd_v2.aleo/register_fld_with_coupon_public(name, parent, receiver, card, is_sgx, timestamp, usd_price);
        messenger.aleo/send(ADMIN_ADDR, memo);
        return register_fld_with_coupon_pub(f);
    }

    async function register_fld_with_coupon_pub(f: Future) {
        f.await();
    }
}
