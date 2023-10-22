// The 'program' program.
import credits.leo;
import aleo_name_service_registry_v1.leo;

program ans_registrar_v1.aleo {
    function calc_price(name: aleo_name_service_registry_v1.leo/Name) -> u64 {
        let mask: u128 = 255u128;
        let val: u128 = name.data1;
        let price: u64 = 1250u64;
        for i: u8 in 1u8 .. 5u8 {
            let new: u128 = val.shr(i * 8u8);
            let b: u128 = new & mask;
            if (b > 0u128) {
                price /= 5u64;
            }
        }
        return price;
    }

    // register a first level domain
    // the self.caller must be the holder of parent ANS name, it can be a program or an account
    transition register_fld(
        name: aleo_name_service_registry_v1.leo/Name,
        receiver: address,
        pay_record: credits.leo/credits
    ) {
        // calc price
        let price: u64 = calc_price(name);
        // this program address receive credits
        let program_address: address = aleo172lc2n6hcaqedj8kktf3sl03a5g8kt8hw0hj7vgp0d0tukn5w5pqcnruw0;
        credits.leo/transfer_private_to_public(pay_record, program_address, price);
        // this is "ans" name hash
        let parent: field = 1920386658975196425550924827100617554000929220648586707605625593907196661967field;
        aleo_name_service_registry_v1.leo/register(name, receiver, parent, 0u128);
    }

    transition register_sub_private(
        name: aleo_name_service_registry_v1.leo/Name,
        receiver: address,
        parent: aleo_name_service_registry_v1.leo/NFT
    ) {
        aleo_name_service_registry_v1.leo/register_private(name, receiver, parent, 0u128);
    }

    transition register_sub_public(
        name: aleo_name_service_registry_v1.leo/Name,
        receiver: address,
        parent: field
    ) {
        aleo_name_service_registry_v1.leo/register_public(name, receiver, parent, 0u128);
    }

    transition claim(amount: u64, receiver: address) {
        assert_eq(self.caller, aleo1sr8d93usu395zc29qcl35ul2e7hl2538hl8pehe4ms88q4g70gxq3ffw0v);
        credits.leo/transfer_public_to_private(receiver, amount);
    }

}
