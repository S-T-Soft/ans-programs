program aleo_name_service_registry_v3.aleo;

record NFT:
    owner as address.private;
    data as field.private;
    edition as scalar.private;


function is_owner:
    input r0 as field.private;
    input r1 as address.private;
    async is_owner r0 r1 into r2;
    output r2 as aleo_name_service_registry_v3.aleo/is_owner.future;

finalize is_owner:
    input r0 as field.public;
    input r1 as address.public;
    assert.eq true true;
