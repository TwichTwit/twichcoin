module twichcoin::twichcoin_tests {
    use sui::test_scenario as ts;
    use sui::clock;
    use sui::clock::Clock;

    use twichcoin::twichcoin;

    const ADMIN: address = @0xA11CE;
    const BENEF: address = @0xB0B;

    #[test]
    fun admin_can_set_beneficiary_start_and_read() {
        let mut s = ts::begin(ADMIN);
        let ctx = ts::ctx(&mut s);

        let mut pool = twichcoin::new_vesting_pool_for_testing(ADMIN, ctx);
        let c: Clock = clock::create_for_testing(ctx);

        // Before start
        let (_a0, b0, _y10, _y20, claimed0, started0, twits0) =
            twichcoin::get_vesting_info(&pool);
        assert!(b0 == @0x0, 100);
        assert!(!claimed0, 101);
        assert!(!started0, 102);
        assert!(twits0 == 0, 103);

        // Set beneficiary
        twichcoin::set_beneficiary(&mut pool, BENEF, ctx);

        // Start vesting
        twichcoin::start_vesting(&mut pool, &c, ctx);

        // Read info
        let (a1, b1, y11, y21, claimed1, started1, twits1) =
            twichcoin::get_vesting_info(&pool);

        assert!(a1 == ADMIN, 110);
        assert!(b1 == BENEF, 111);
        assert!(started1, 112);
        assert!(!claimed1, 113);
        assert!(y21 > y11, 114);
        assert!(twits1 == 0, 115);

        // Helpers
        let rem_twich = twichcoin::get_remaining_twiches(&pool);
        let rem_twits = twichcoin::get_remaining_twits(&pool);
        assert!(rem_twich == 0, 120);
        assert!(rem_twits == 0, 121);

        // Cleanup
        clock::destroy_for_testing(c);

        // IMPORTANT: pool was created in-test, so transfer it to consume it
        transfer::public_transfer(pool, ADMIN);

        ts::end(s);
    }
}