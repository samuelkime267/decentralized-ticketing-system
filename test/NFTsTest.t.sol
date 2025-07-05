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
    address MANAGER = makeAddr("manager");
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

    function testDeployerCanSetManager() public setManager {
        assertEq(ticketNft.getEventManager(), MANAGER);
        assertEq(popNft.getEventManager(), MANAGER);
    }

    function testUserCanMintTicketNFT() public setManager {
        vm.prank(MANAGER);
        ticketNft.mint(USER, DEFAULT_EVENT_ID, DEFAULT_URI);
        assertEq(ticketNft.balanceOf(USER), 1);
    }

    function testUserCanMintPopNFT() public setManager {
        vm.prank(MANAGER);
        popNft.mint(USER, DEFAULT_EVENT_ID, DEFAULT_URI);
        assertEq(popNft.balanceOf(USER), 1);
    }

    function testIdIncreasesAfterMinting() public setManager {
        vm.prank(MANAGER);
        ticketNft.mint(USER, DEFAULT_EVENT_ID, DEFAULT_URI);
        assertEq(ticketNft.getTokenIdCounter(), 2);

        vm.prank(MANAGER);
        popNft.mint(USER, DEFAULT_EVENT_ID, DEFAULT_URI);
        assertEq(popNft.getTokenIdCounter(), 2);
    }

    function testMintSetsValuesProperly() public setManager {
        vm.prank(MANAGER);
        ticketNft.mint(USER, DEFAULT_EVENT_ID, DEFAULT_URI);
        assertEq(ticketNft.getEventId(1), DEFAULT_EVENT_ID);
        assertEq(ticketNft.tokenURI(1), DEFAULT_URI);

        vm.prank(MANAGER);
        popNft.mint(USER, DEFAULT_EVENT_ID, DEFAULT_URI);
        assertEq(popNft.getEventId(1), DEFAULT_EVENT_ID);
        assertEq(popNft.tokenURI(1), DEFAULT_URI);
    }

    modifier setManager() {
        vm.prank(DEPLOYER);
        ticketNft.setEventManager(MANAGER);

        vm.prank(DEPLOYER);
        popNft.setEventManager(MANAGER);

        _;
    }
}
