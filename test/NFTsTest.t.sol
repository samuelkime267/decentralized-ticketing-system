// SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {DeployNFTs} from "../script/DeployNFTs.sol";
import {EventStorage} from "../src/EventStorage.sol";
import {console} from "forge-std/console.sol";
import {TicketNFT} from "../src/TicketNFT.sol";
import {PoPNFT} from "../src/PoPNFT.sol";

contract NFTsTest is Test {
    TicketNFT ticketNft;
    PoPNFT popNft;

    address DEPLOYER = makeAddr("deployer");
    address USER = makeAddr("user");
    uint256 public constant STARTING_BALANCE = 10 ether;
    uint256 constant DEFAULT_EVENT_ID = 1;
    string constant DEFAULT_URI = "url://";

    function setUp() external {
        (ticketNft, popNft) = new DeployNFTs().run(DEPLOYER);

        vm.deal(USER, STARTING_BALANCE);
        vm.deal(DEPLOYER, STARTING_BALANCE);
    }

    function testTokenIdCounterStartsFromOne() public view {
        assertEq(ticketNft.getTokenIdCounter(), 1);
        assertEq(popNft.getTokenIdCounter(), 1);
    }

    function testOnlyManagerCanMint() public {
        vm.expectRevert(TicketNFT.TicketNFT__NotEventManager.selector);
        ticketNft.mint(USER, DEFAULT_EVENT_ID, DEFAULT_URI);

        vm.expectRevert(PoPNFT.PoPNFT__NotEventManager.selector);
        popNft.mint(USER, DEFAULT_EVENT_ID, DEFAULT_URI);
    }
}
