import credits.aleo;
import aleo_name_service_registry_v1.aleo;
program ans_registrar_v1.aleo;






closure calc_price:
    input r0 as aleo_name_service_registry_v1.aleo/Name.record;
    mul 1u8 8u8 into r1;
    shr r0.data1 r1 into r2;
    and r2 255u128 into r3;
    gt r3 0u128 into r4;
    div 1250u64 5u64 into r5;
    ternary r4 r5 1250u64 into r6;
    mul 2u8 8u8 into r7;
    shr r0.data1 r7 into r8;
    and r8 255u128 into r9;
    gt r9 0u128 into r10;
    div r6 5u64 into r11;
    ternary r10 r11 r6 into r12;
    mul 3u8 8u8 into r13;
    shr r0.data1 r13 into r14;
    and r14 255u128 into r15;
    gt r15 0u128 into r16;
    div r12 5u64 into r17;
    ternary r16 r17 r12 into r18;
    mul 4u8 8u8 into r19;
    shr r0.data1 r19 into r20;
    and r20 255u128 into r21;
    gt r21 0u128 into r22;
    div r18 5u64 into r23;
    ternary r22 r23 r18 into r24;
    output r24 as u64;


function register_fld:
    input r0 as aleo_name_service_registry_v1.aleo/Name.record;
    input r1 as address.private;
    input r2 as credits.aleo/credits.record;
    call calc_price r0 into r3;
    call credits.aleo/transfer_private_to_public r2 aleo172lc2n6hcaqedj8kktf3sl03a5g8kt8hw0hj7vgp0d0tukn5w5pqcnruw0 r3;
    call aleo_name_service_registry_v1.aleo/register r0 r1 1920386658975196425550924827100617554000929220648586707605625593907196661967field 0u128;


function register_sub_private:
    input r0 as aleo_name_service_registry_v1.aleo/Name.record;
    input r1 as address.private;
    input r2 as aleo_name_service_registry_v1.aleo/NFT.record;
    call aleo_name_service_registry_v1.aleo/register_private r0 r1 r2 0u128;


function register_sub_public:
    input r0 as aleo_name_service_registry_v1.aleo/Name.record;
    input r1 as address.private;
    input r2 as field.private;
    call aleo_name_service_registry_v1.aleo/register_public r0 r1 r2 0u128;


function claim:
    input r0 as u64.private;
    input r1 as address.private;
    assert.eq self.caller aleo1sr8d93usu395zc29qcl35ul2e7hl2538hl8pehe4ms88q4g70gxq3ffw0v;
    call credits.aleo/transfer_public_to_private r1 r0;
