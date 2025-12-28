module 0x0::twichcoin {
    use sui::coin_registry;
    use sui::coin::Coin;
    use sui::balance::Balance;  
    use sui::clock::Clock;
    use std::string;

    /// One-time witness (OTW)
    public struct TWICHCOIN has drop {}

    const DECIMALS: u8 = 9;
    const TWITS_PER_TWICH: u64 = 1_000_000_000;

    // Total = 1,000,000,000 TWICH * 1e9 = 1e18 twits
    const TOTAL_SUPPLY_TWITS: u64 = 1_000_000_000_000_000_000;

    // Vesting total = 10% = 100,000,000 TWICH = 1e17 twits
    const VESTING_TWITS: u64 = 100_000_000_000_000_000;

    // Tranche = 5% = 50,000,000 TWICH = 5e16 twits
    const TRANCHE_TWITS: u64 = 50_000_000_000_000_000;

    const ONE_YEAR_MS: u64 = 31_536_000_000;
    const TWO_YEARS_MS: u64 = 63_072_000_000;

    const E_NOT_ADMIN: u64 = 0;
    const E_BENEFICIARY_ALREADY_SET: u64 = 1;
    const E_BENEFICIARY_NOT_SET: u64 = 2;
    const E_VESTING_ALREADY_STARTED: u64 = 3;
    const E_VESTING_NOT_STARTED: u64 = 4;
    const E_NOT_BENEFICIARY: u64 = 5;
    const E_NOT_UNLOCKED: u64 = 6;
    const E_ALREADY_CLAIMED: u64 = 7;
    const E_INSUFFICIENT: u64 = 8;

    public struct VestingPool has key, store {
        id: UID,
        admin: address,
        beneficiary: address,
        unlock_year1_ms: u64,
        unlock_year2_ms: u64,
        claimed_year1: bool,
        started: bool,
        balance_twits: Balance<TWICHCOIN>,
    }

    /// Runs once at publish
    fun init(witness: TWICHCOIN, ctx: &mut TxContext) {
        let (mut builder, mut treasury_cap) = coin_registry::new_currency_with_otw(
            witness,
            DECIMALS,
            string::utf8(b"TWICH"),
            string::utf8(b"TwichCoin"),
            string::utf8(
                b"TwichCoin: fixed supply 1,000,000,000 twiches (9 decimals; twits). 10% vesting: 5% after 1 year, 5% after 2 years. The unofficial coin for stream watchers, chatters, and digital campfire enthusiasts. Not affiliated with any streaming platform. (C) TwichTwit, Dec 2025"
            ),
            string::utf8(
                b"https://blue-select-opossum-370.mypinata.cloud/ipfs/bafybeie5mg2z37k6ssdbyxxnakdj6imgys7p5u77yx5poalbaqyxhwwwlm"
            ),
            ctx,
        );

        let sender = tx_context::sender(ctx);

        let mut supply: Coin<TWICHCOIN> = treasury_cap.mint(TOTAL_SUPPLY_TWITS, ctx);

        // Split 10% into vesting pool
        let vesting_coin = supply.split(VESTING_TWITS, ctx);

        let pool = VestingPool {
            id: object::new(ctx),
            admin: sender,
            beneficiary: @0x0,
            unlock_year1_ms: 0,
            unlock_year2_ms: 0,
            claimed_year1: false,
            started: false,
            balance_twits: vesting_coin.into_balance(),
        };

        // Transfer 90% to publisher
        transfer::public_transfer(supply, sender);

        // Fix supply forever
        builder.make_supply_fixed(treasury_cap);
        coin_registry::finalize_and_delete_metadata_cap(builder, ctx);
        transfer::public_transfer(pool, sender);
    }

    /// Starts the vesting schedule (admin only, once).
    /// - year1 unlock = now + 1 year
    /// - year2 unlock = now + 2 years
    public fun start_vesting(pool: &mut VestingPool, clock: &Clock, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(sender == pool.admin, E_NOT_ADMIN);
        assert!(!pool.started, E_VESTING_ALREADY_STARTED);

        let now = sui::clock::timestamp_ms(clock);
        pool.unlock_year1_ms = now + ONE_YEAR_MS;
        pool.unlock_year2_ms = now + TWO_YEARS_MS;
        pool.started = true;
    }

    /// Sets beneficiary once (admin only). Does not affect timing.
    public fun set_beneficiary(pool: &mut VestingPool, beneficiary: address, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(sender == pool.admin, E_NOT_ADMIN);
        assert!(pool.beneficiary == @0x0, E_BENEFICIARY_ALREADY_SET);

        pool.beneficiary = beneficiary;
    }

    /// Claim first tranche (5%) after year 1. Returns the claimed Coin.
    public fun claim_year1(pool: &mut VestingPool, clock: &Clock, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        assert!(pool.beneficiary != @0x0, E_BENEFICIARY_NOT_SET);
        assert!(sender == pool.beneficiary, E_NOT_BENEFICIARY);
        assert!(pool.started, E_VESTING_NOT_STARTED);
        assert!(!pool.claimed_year1, E_ALREADY_CLAIMED);

        let now = sui::clock::timestamp_ms(clock);
        assert!(now >= pool.unlock_year1_ms, E_NOT_UNLOCKED);

        assert!(sui::balance::value(&pool.balance_twits) >= TRANCHE_TWITS, E_INSUFFICIENT);
        let tranche: Balance<TWICHCOIN> = sui::balance::split(&mut pool.balance_twits, TRANCHE_TWITS);

        pool.claimed_year1 = true;

        let coin = tranche.into_coin(ctx);
        transfer::public_transfer(coin, pool.beneficiary);
    }

    /// Claim remaining tranche after year 2.
    /// Consumes the pool and returns ALL remaining Coin (5% if year1 claimed, 10% otherwise).
    public fun claim_year2(pool: VestingPool, clock: &Clock, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        assert!(pool.beneficiary != @0x0, E_BENEFICIARY_NOT_SET);
        assert!(sender == pool.beneficiary, E_NOT_BENEFICIARY);
        assert!(pool.started, E_VESTING_NOT_STARTED);

        let now = sui::clock::timestamp_ms(clock);
        assert!(now >= pool.unlock_year2_ms, E_NOT_UNLOCKED);

        // Save beneficiary before destructuring (so we can transfer after consuming `pool`)
        let beneficiary = pool.beneficiary;

        let VestingPool {
            id,
            admin: _,
            beneficiary: _,
            unlock_year1_ms: _,
            unlock_year2_ms: _,
            claimed_year1: _,
            started: _,
            balance_twits,
        } = pool;

        object::delete(id);

        let coin = balance_twits.into_coin(ctx);
        transfer::public_transfer(coin, beneficiary);
    }

    /// Get vesting information (anyone can call)
    public fun get_vesting_info(pool: &VestingPool): (address, address, u64, u64, bool, bool, u64) {
        (
            pool.admin,
            pool.beneficiary,
            pool.unlock_year1_ms,
            pool.unlock_year2_ms,
            pool.claimed_year1,
            pool.started,
            sui::balance::value(&pool.balance_twits)
        )
    }

    /// Get remaining balance in TWICH (not twits)
    public fun get_remaining_twiches(pool: &VestingPool): u64 {
        sui::balance::value(&pool.balance_twits) / TWITS_PER_TWICH
    }

    /// Get remaining balance in twits (smallest unit)
    public fun get_remaining_twits(pool: &VestingPool): u64 {
        sui::balance::value(&pool.balance_twits)
    }

    #[test_only]
    public fun new_vesting_pool_for_testing(admin: address, ctx: &mut TxContext): VestingPool {
        VestingPool {
            id: object::new(ctx),
            admin,
            beneficiary: @0x0,
            unlock_year1_ms: 0,
            unlock_year2_ms: 0,
            claimed_year1: false,
            started: false,
            balance_twits: sui::balance::zero<TWICHCOIN>(),
        }
    }
}


