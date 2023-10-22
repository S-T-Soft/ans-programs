program aleo_name_service_registry_v1.aleo;

struct Name:
    data1 as u128;
    data2 as u128;
    data3 as u128;
    data4 as u128;

struct TokenId:
    data1 as u128;
    data2 as u128;
    data3 as u128;
    data4 as u128;
    parent as field;
    resolver as u128;

record NFT:
    owner as address.private;
    data as TokenId.private;
    edition as scalar.private;


function register:
    input r0 as Name.private;
    input r1 as address.private;
    input r2 as field.private;
    input r3 as u128.private;


function register_private:
    input r0 as Name.private;
    input r1 as address.private;
    input r2 as NFT.record;
    input r3 as u128.private;


function register_public:
    input r0 as Name.private;
    input r1 as address.private;
    input r2 as field.private;
    input r3 as u128.private;
