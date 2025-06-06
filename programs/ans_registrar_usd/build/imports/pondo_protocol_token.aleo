import credits.aleo;
import token_registry.aleo;

program pondo_protocol_token.aleo;

struct TokenMetadata:
    token_id as field;
    name as u128;
    symbol as u128;
    decimals as u8;
    supply as u128;
    max_supply as u128;
    admin as address;
    external_authorization_required as boolean;
    external_authorization_party as address;

struct TokenOwner:
    account as address;
    token_id as field;

struct Balance:
    token_id as field;
    account as address;
    balance as u128;
    authorized_until as u32;

mapping has_minted:
    key as u8.public;
    value as boolean.public;

function mint_public:
    assert.eq self.caller aleo1hmrpe0ts2khluprhex3y46cqqy44pme7lwc40ls9nexftx0xhu8sxxpnd0 ;
    call token_registry.aleo/mint_public 1751493913335802797273486270793650302076377624243810059080883537084141842601field aleo1hmrpe0ts2khluprhex3y46cqqy44pme7lwc40ls9nexftx0xhu8sxxpnd0 1000000000000000u128 4294967295u32 into r0;
    async mint_public r0 into r1;
    output r1 as pondo_protocol_token.aleo/mint_public.future;

finalize mint_public:
    input r0 as token_registry.aleo/mint_public.future;
    await r0;
    contains has_minted[0u8] into r1;
    not r1 into r2;
    assert.eq r2 true ;
    set true into has_minted[0u8];

function burn_public:
    input r0 as address.public;
    input r1 as u128.public;
    input r2 as u128.public;
    gt r1 0u128 into r3;
    assert.eq r3 true ;
    gt r2 0u128 into r4;
    assert.eq r4 true ;
    is.eq self.signer r0 into r5;
    is.eq self.caller r0 into r6;
    or r5 r6 into r7;
    assert.eq r7 true ;
    call token_registry.aleo/burn_public 1751493913335802797273486270793650302076377624243810059080883537084141842601field r0 r1 into r8;
    call token_registry.aleo/transfer_public 1751493913335802797273486270793650302076377624243810059080883537084141842600field r0 r2 into r9;
    async burn_public r8 r9 r1 r2 into r10;
    output r10 as pondo_protocol_token.aleo/burn_public.future;

finalize burn_public:
    input r0 as token_registry.aleo/burn_public.future;
    input r1 as token_registry.aleo/transfer_public.future;
    input r2 as u128.public;
    input r3 as u128.public;
    await r0;
    await r1;
    get token_registry.aleo/registered_tokens[1751493913335802797273486270793650302076377624243810059080883537084141842601field] into r4;
    cast pondo_protocol_token.aleo 1751493913335802797273486270793650302076377624243810059080883537084141842600field into r5 as TokenOwner;
    hash.bhp256 r5 into r6 as field;
    get token_registry.aleo/authorized_balances[r6] into r7;
    mul r4.supply 1000000u128 into r8;
    div r8 r7.balance into r9;
    mul r2 1000000u128 into r10;
    div r10 r3 into r11;
    lte r9 r11 into r12;
    assert.eq r12 true ;

function initialize_token:
    assert.eq self.caller pondo_protocol.aleo ;
    call token_registry.aleo/register_token 1751493913335802797273486270793650302076377624243810059080883537084141842601field 97240284627655645872219502u128 1347306575u128 6u8 1000000000000000u128 false pondo_protocol_token.aleo into r0;
    async initialize_token r0 into r1;
    output r1 as pondo_protocol_token.aleo/initialize_token.future;

finalize initialize_token:
    input r0 as token_registry.aleo/register_token.future;
    await r0;
