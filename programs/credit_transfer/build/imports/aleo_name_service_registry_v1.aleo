program aleo_name_service_registry_v1.aleo;

record NFT:
    owner as address.private;
    data as field.private;
    edition as scalar.private;


function check_ownship:
    input r0 as field.private;
    input r1 as address.private;
    async check_ownship r0 r1 into r2;
    output r2 as aleo_name_service_registry_v1.aleo/check_ownship.future;

finalize check_ownship:
    input r0 as field.public;
    input r1 as address.public;
    assert.eq true true;
