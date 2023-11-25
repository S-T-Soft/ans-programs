import credits.aleo;
import aleo_name_service_registry_v2.aleo;
program ans_registrar_v2.aleo;




mapping general_settings:
	key as u8.public;
	value as u128.public;

closure calc_price:
    input r0 as [u128; 4u32];
    gt r0[0u32] 4294967295u128 into r1;
    gt r0[0u32] 16777215u128 into r2;
    gt r0[0u32] 65535u128 into r3;
    gt r0[0u32] 255u128 into r4;
    ternary r4 250000000u64 1250000000u64 into r5;
    ternary r3 50000000u64 r5 into r6;
    ternary r2 10000000u64 r6 into r7;
    ternary r1 2000000u64 r7 into r8;
    output r8 as u64;


function initialize:
    hash.bhp256 self.caller into r0 as u128;
    async initialize r0 into r1;
    output r1 as ans_registrar_v2.aleo/initialize.future;

finalize initialize:
    input r0 as u128.public;
    set r0 into general_settings[0u8];
    set 1u128 into general_settings[1u8];


function set_minting_flag:
    input r0 as u128.private;
    hash.bhp256 self.caller into r1 as u128;
    async set_minting_flag r1 r0 into r2;
    output r2 as ans_registrar_v2.aleo/set_minting_flag.future;

finalize set_minting_flag:
    input r0 as u128.public;
    input r1 as u128.public;
    get general_settings[0u8] into r2;
    assert.eq r0 r2;
    set r1 into general_settings[1u8];


function set_admin:
    input r0 as address.private;
    hash.bhp256 self.caller into r1 as u128;
    hash.bhp256 r0 into r2 as u128;
    async set_admin r1 r2 into r3;
    output r3 as ans_registrar_v2.aleo/set_admin.future;

finalize set_admin:
    input r0 as u128.public;
    input r1 as u128.public;
    get general_settings[0u8] into r2;
    assert.eq r0 r2;
    set r1 into general_settings[7u8];


function register_fld:
    input r0 as [u128; 4u32].private;
    input r1 as address.private;
    input r2 as credits.aleo/credits.record;
    call calc_price r0 into r3;
    call credits.aleo/transfer_private_to_public r2 aleo1tf9qymuyszzk38t0dyxgex9sk9s4mugajv6m9g49nuny2mna9q8sq06rhv r3 into r4 r5;
    call aleo_name_service_registry_v2.aleo/register r0 3601410589032411677092457044111621862970800028849492457114786804129430260029field r1 0u128 into r6 r7;
    async register_fld r5 r7 into r8;
    output r8 as ans_registrar_v2.aleo/register_fld.future;

finalize register_fld:
    input r0 as credits.aleo/transfer_private_to_public.future;
    input r1 as aleo_name_service_registry_v2.aleo/register.future;
    await r0;
    await r1;
    get general_settings[1u8] into r2;
    assert.eq r2 1u128;


function claim:
    input r0 as u64.private;
    input r1 as address.private;
    hash.bhp256 self.caller into r2 as u128;
    call credits.aleo/transfer_public_to_private r1 r0 into r3 r4;
    async claim r4 r2 into r5;
    output r5 as ans_registrar_v2.aleo/claim.future;

finalize claim:
    input r0 as credits.aleo/transfer_public_to_private.future;
    input r1 as u128.public;
    await r0;
    get general_settings[0u8] into r2;
    assert.eq r1 r2;
