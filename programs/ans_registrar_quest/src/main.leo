import credits.aleo;
import ans_registrar.aleo;
import messenger.aleo;

program ans_registrar_quest.aleo {
    const ADMIN_ADDR: address = aleo1anscwvx9zhwm3yyzgef8c3nt36tmm0g4juhk4gxeavcwcz7t6v9qwnlue9;

    // register with coupon card
    async transition register_free(
        name: [u128; 4],
        parent: field,
        receiver: address,
        card: ans_coupon_card.aleo/CouponCard,
        memo: [field; 8]
    ) -> Future {
        let f: Future = ans_registrar.aleo/register_free(name, parent, receiver, card);
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
        memo: [field; 8]
    ) -> Future {
        let f: Future = ans_registrar.aleo/register_fld(name, parent, receiver, pay_record);
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
        memo: [field; 8]
    ) -> Future {
        let f: Future = ans_registrar.aleo/register_fld_public(name, parent, receiver);
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
        card: ans_coupon_card.aleo/CouponCard,
        memo: [field; 8]
    ) -> Future {
        let f: Future = ans_registrar.aleo/register_fld_with_coupon(name, parent, receiver, pay_record, card);
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
        card: ans_coupon_card.aleo/CouponCard,
        memo: [field; 8]
    ) -> Future {
        let f: Future = ans_registrar.aleo/register_fld_with_coupon_public(name, parent, receiver, card);
        messenger.aleo/send(ADMIN_ADDR, memo);
        return register_fld_with_coupon_pub(f);
    }

    async function register_fld_with_coupon_pub(f: Future) {
        f.await();
    }
}
