import credits.aleo;
import aleo_name_service_registry_v1.aleo;
program ans_registrar_v1.aleo;





mapping general_settings:
	key as u8.public;
	value as u128.public;

closure calc_price:
    input r0 as [u128; 4u32];
    mul 1u8 8u8 into r1;
    shr r0[0u32] r1 into r2;
    and r2 255u128 into r3;
    gt r3 0u128 into r4;
    div 1250000000u64 5u64 into r5;
    ternary r4 r5 1250000000u64 into r6;
    mul 2u8 8u8 into r7;
    shr r0[0u32] r7 into r8;
    and r8 255u128 into r9;
    gt r9 0u128 into r10;
    div r6 5u64 into r11;
    ternary r10 r11 r6 into r12;
    mul 3u8 8u8 into r13;
    shr r0[0u32] r13 into r14;
    and r14 255u128 into r15;
    gt r15 0u128 into r16;
    div r12 5u64 into r17;
    ternary r16 r17 r12 into r18;
    mul 4u8 8u8 into r19;
    shr r0[0u32] r19 into r20;
    and r20 255u128 into r21;
    gt r21 0u128 into r22;
    div r18 5u64 into r23;
    ternary r22 r23 r18 into r24;
    output r24 as u64;


function initialize:
    hash.bhp256 self.caller into r0 as u128;
    async initialize r0 into r1;
    output r1 as ans_registrar_v1.aleo/initialize.future;

finalize initialize:
    input r0 as u128.public;
    set r0 into general_settings[0u8];
    set 1u128 into general_settings[1u8];


function set_minting_flag:
    input r0 as u128.private;
    hash.bhp256 self.caller into r1 as u128;
    async set_minting_flag r1 r0 into r2;
    output r2 as ans_registrar_v1.aleo/set_minting_flag.future;

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
    output r3 as ans_registrar_v1.aleo/set_admin.future;

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
    call credits.aleo/transfer_private_to_public r2 aleo172lc2n6hcaqedj8kktf3sl03a5g8kt8hw0hj7vgp0d0tukn5w5pqcnruw0 r3 into r4 r5;
    call aleo_name_service_registry_v1.aleo/register r0 3601410589032411677092457044111621862970800028849492457114786804129430260029field r1 0u128 into r6 r7;
    async register_fld r5 r7 into r8;
    output r8 as ans_registrar_v1.aleo/register_fld.future;

finalize register_fld:
    input r0 as credits.aleo/transfer_private_to_public.future;
    input r1 as aleo_name_service_registry_v1.aleo/register.future;
    await r0;
    await r1;
    get general_settings[1u8] into r2;
    assert.eq r2 1u128;


function register_sub_private:
    input r0 as [u128; 4u32].private;
    input r1 as address.private;
    input r2 as aleo_name_service_registry_v1.aleo/NFT.record;
    call aleo_name_service_registry_v1.aleo/register_private r0 r2 r1 0u128 into r3 r4 r5;
    async register_sub_private r5 into r6;
    output r6 as ans_registrar_v1.aleo/register_sub_private.future;

finalize register_sub_private:
    input r0 as aleo_name_service_registry_v1.aleo/register_private.future;
    await r0;
    get general_settings[1u8] into r1;
    assert.eq r1 1u128;


function register_sub_public:
    input r0 as [u128; 4u32].private;
    input r1 as address.private;
    input r2 as field.private;
    call aleo_name_service_registry_v1.aleo/register_public r0 r2 r1 0u128 into r3 r4;
    async register_sub_public r4 into r5;
    output r5 as ans_registrar_v1.aleo/register_sub_public.future;

finalize register_sub_public:
    input r0 as aleo_name_service_registry_v1.aleo/register_public.future;
    await r0;
    get general_settings[1u8] into r1;
    assert.eq r1 1u128;


function claim:
    input r0 as u64.private;
    input r1 as address.private;
    hash.bhp256 self.caller into r2 as u128;
    call credits.aleo/transfer_public_to_private r1 r0 into r3 r4;
    async claim r4 r2 into r5;
    output r5 as ans_registrar_v1.aleo/claim.future;

finalize claim:
    input r0 as credits.aleo/transfer_public_to_private.future;
    input r1 as u128.public;
    await r0;
    get general_settings[0u8] into r2;
    assert.eq r1 r2;
