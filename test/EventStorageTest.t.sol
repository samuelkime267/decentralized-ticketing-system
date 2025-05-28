// SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {DeployEventStorage} from "../script/DeployEventStorage.s.sol";
import {EventStorage} from "../src/EventStorage.sol";
import {console} from "forge-std/console.sol";
import {TicketNFT} from "../src/TicketNFT.sol";
import {PoPNFT} from "../src/PoPNFT.sol";

contract EventStorageTest is Test {
    EventStorage eventStorage;
    uint256 initialEventId = 1;
    address public EVENTCREATOR = makeAddr("eventCreator");
    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user2");
    address public USER3 = makeAddr("user3");
    address public USER4 = makeAddr("user4");
    address public USER5 = makeAddr("user5");
    address[] public users = [USER, USER2, USER3, USER4, USER5];
    uint256 public constant STARTING_BALANCE = 10 ether;

    EventStorage.CreateEventInput input = EventStorage.CreateEventInput({
        name: "No pizza for me",
        description: "I wanted to eat pizza but stayed home",
        location: "An unknown place",
        startTime: 0,
        endTime: 0,
        metaDataUri: "uri://",
        price: 1 ether,
        ticketBaseTokenUri: "uri://",
        ticketNFTName: "Pizza Pass",
        ticketNFTSymbol: "PP",
        popBaseTokenUri: "uri://",
        popNFTName: "You Chop",
        popNFTSymbol: "YC"
    });

    function setUp() public {
        eventStorage = new DeployEventStorage().run();
        input.startTime = block.timestamp + 1000000;
        input.endTime = block.timestamp + 10000000;

        for (uint256 i = 0; i < users.length; i++) {
            vm.deal(users[i], STARTING_BALANCE);
        }
        vm.deal(EVENTCREATOR, STARTING_BALANCE);
    }

    function testTicketAndPoPNftsAreDeployedOnContractCreation() public view {
        assert(eventStorage.getTicketNFT() != address(0));
        assert(eventStorage.getPopNFT() != address(0));
    }

    function testEventIdIncreases() public createEvent {
        assertEq(eventStorage.getEventId(), initialEventId + 1);
    }

    function testIfCreatedEventHasInitialEventId() public createEvent {
        assert(eventStorage.getEvent(initialEventId).id != 0);
    }

    function testIfEventDataMatchesInitialData() public createEvent {
        EventStorage.Event memory ev = eventStorage.getEvent(initialEventId);
        assertEq(ev.name, input.name);
        assertEq(ev.eventCreator, EVENTCREATOR);
        assertEq(ev.description, input.description);
        assertEq(ev.location, input.location);
        assertEq(ev.startTime, input.startTime);
        assertEq(ev.endTime, input.endTime);
        assertEq(ev.metaDataUri, input.metaDataUri);
        assertEq(ev.price, input.price);
    }

    function testEventCreationFailsIfTimeStartTimeHasPassed() public {
        input.startTime = block.timestamp - 1;

        vm.expectRevert(EventStorage.EventStorage__EventCannotStartBeforeCreation.selector);
        eventStorage.createEvent(input);
    }

    function testEventIsEmittedAfterEventCreation() public {
        vm.expectEmit(true, true, true, false);
        emit EventStorage.EventCreated(initialEventId, input.name, EVENTCREATOR);
        vm.prank(EVENTCREATOR);
        eventStorage.createEvent(input);
    }

    function testCannotByTicketsForEventThatDoesNotExist() public {
        vm.expectRevert(EventStorage.EventStorage__EventDoesNotExist.selector);
        eventStorage.buyTicket(initialEventId);
    }

    function testCannotBuyTicketWithInsufficientPrice() public createEvent {
        vm.prank(USER);
        vm.expectRevert(EventStorage.EventStorage__InsufficientFunds.selector);
        eventStorage.buyTicket(initialEventId);
    }

    function testBuyingTicketFailsIFEventHasEnded() public createEvent {
        vm.warp(input.endTime + 1);
        vm.roll(block.number + 1);

        vm.expectRevert(EventStorage.EventStorage__EventHasEnded.selector);
        vm.prank(USER);
        eventStorage.buyTicket{value: input.price}(initialEventId);
    }

    function testUserTicketIsTrueAfterBuying() public createEvent {
        vm.prank(USER);
        eventStorage.buyTicket{value: input.price}(initialEventId);
        console.log(eventStorage.getTicket(USER, initialEventId));
        assert(eventStorage.getTicket(USER, initialEventId));
    }

    function testCannotSaveAttendanceIfEventDoesNotExist() public {
        vm.expectRevert(EventStorage.EventStorage__EventDoesNotExist.selector);
        eventStorage.saveAttendance(initialEventId);
    }

    function testIfUserDoesNotHaveTicketItReverts() public createEvent {
        vm.expectRevert(EventStorage.EventStorage__DoesNotHaveTicket.selector);
        vm.prank(USER);
        eventStorage.saveAttendance(initialEventId);
    }

    function testCannotSaveAttendanceBeforeEventStarts() public createEvent {
        vm.prank(USER);
        eventStorage.buyTicket{value: input.price}(initialEventId);
        vm.expectRevert(EventStorage.EventStorage__EventHasNotStarted.selector);
        vm.prank(USER);
        eventStorage.saveAttendance(initialEventId);
    }

    function testUserCannotSaveAttendanceAfterEventHasEnded() public createEvent {
        vm.prank(USER);
        eventStorage.buyTicket{value: input.price}(initialEventId);
        vm.warp(input.endTime + 1);
        vm.roll(block.number + 1);
        vm.expectRevert(EventStorage.EventStorage__EventHasEnded.selector);
        vm.prank(USER);
        eventStorage.saveAttendance(initialEventId);
    }

    function testAttendanceIsSaved() public createEvent {
        vm.prank(USER);
        eventStorage.buyTicket{value: input.price}(initialEventId);
        vm.warp(input.startTime + 1);
        vm.roll(block.number + 1);
        vm.prank(USER);
        eventStorage.saveAttendance(initialEventId);
        assert(eventStorage.getPop(USER, initialEventId));
    }

    function testCreatorIsMintedTicketNFT() public createEvent {
        TicketNFT ticketNft = TicketNFT(eventStorage.getTicketNFT());
        assert(ticketNft.balanceOf(EVENTCREATOR) == 1);
    }

    function testCreatorCannotBuyTicketMultipleTimes() public createEvent {
        vm.prank(EVENTCREATOR);
        vm.expectRevert(EventStorage.EventStorage__YouAlreadyHaveATicket.selector);
        eventStorage.buyTicket{value: input.price}(initialEventId);
    }

    function testUserCannotBuyTicketMultipleTimes() public createEvent {
        vm.prank(USER);
        eventStorage.buyTicket{value: input.price}(initialEventId);

        vm.prank(USER);
        vm.expectRevert(EventStorage.EventStorage__YouAlreadyHaveATicket.selector);
        eventStorage.buyTicket{value: input.price}(initialEventId);
    }

    function testUserIsMintedTicketNFTAfterBuying() public createEvent {
        vm.prank(USER);
        eventStorage.buyTicket{value: input.price}(initialEventId);

        TicketNFT ticketNft = TicketNFT(eventStorage.getTicketNFT());
        assert(ticketNft.balanceOf(USER) == 1);
    }

    function testUserIsMintedPopNFTAfterSavingAttendance() public createEvent {
        vm.prank(USER);
        eventStorage.buyTicket{value: input.price}(initialEventId);

        vm.warp(input.startTime + 1);
        vm.roll(block.number + 1);

        vm.prank(USER);
        eventStorage.saveAttendance(initialEventId);

        PoPNFT popNft = PoPNFT(eventStorage.getPopNFT());
        assert(popNft.balanceOf(USER) == 1);
    }

    function testMultipleUsersCanBuyTicketsAndGetNfts() public createEvent {
        for (uint256 i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            eventStorage.buyTicket{value: input.price}(initialEventId);
        }

        for (uint256 i = 0; i < users.length; i++) {
            TicketNFT ticketNft = TicketNFT(eventStorage.getTicketNFT());
            assert(ticketNft.balanceOf(users[i]) == 1);
        }
    }

    function testMultipleUsersCanBuyTicketsAlsoSaveAttendanceAndGetNFTS() public createEvent {
        for (uint256 i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            eventStorage.buyTicket{value: input.price}(initialEventId);
        }

        vm.warp(input.startTime + 1);
        vm.roll(block.number + 1);

        for (uint256 i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            eventStorage.saveAttendance(initialEventId);
        }

        for (uint256 i = 0; i < users.length; i++) {
            TicketNFT ticketNft = TicketNFT(eventStorage.getTicketNFT());
            assert(ticketNft.balanceOf(users[i]) == 1);
        }

        for (uint256 i = 0; i < users.length; i++) {
            PoPNFT popNft = PoPNFT(eventStorage.getPopNFT());
            assert(popNft.balanceOf(users[i]) == 1);
        }
    }

    modifier createEvent() {
        vm.prank(EVENTCREATOR);
        eventStorage.createEvent(input);
        _;
    }
}
