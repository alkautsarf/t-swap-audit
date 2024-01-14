// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {Handler} from "./Handler.t.sol";

contract Invariant is StdInvariant, Test {
    ERC20Mock public poolToken;
    ERC20Mock public weth;

    PoolFactory public factory;
    TSwapPool public pool;

    Handler public handler;

    int256 public constant STARTING_X = 100e18; //ii Starting ERC20 / poolToken
    int256 public constant STARTING_Y = 50e18; //ii Starting WETH

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        pool.deposit(uint256(STARTING_Y), uint256(STARTING_Y), uint256(STARTING_X), uint64(block.timestamp));

        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetContract(address(handler));
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function statefulFuzz_constantProductFormulaX() public {
        //ii The change in pool size of WETH should follow this function:
        /* 
        * ∆x = (β/(1-β)) * (1/γ) * x
        * ∆y = (αγ/1+αγ) * y
        */
        assertEq(handler.actualDeltaX(),handler.expectedDeltaX());
    }

    function statefulFuzz_constantProductFormulaY() public {
        //ii The change in pool size of WETH should follow this function:
        /* 
        * ∆x = (β/(1-β)) * (1/γ) * x
        * ∆y = (αγ/1+αγ) * y
        */
        assertEq(handler.actualDeltaY(),handler.expectedDeltaY());
    }
}