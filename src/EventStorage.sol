// SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.23;

import {TicketNFT} from "./TicketNFT.sol";
import {PoPNFT} from "./PoPNFT.sol";

contract EventStorage {
    /////////////////////////////////////////////////////////////////////////
    // Errors
    /////////////////////////////////////////////////////////////////////////
    error EventStorage__EventAlreadyExists();
    error EventStorage__EventDoesNotExist();
    error EventStorage__InsufficientFunds();
    error EventStorage__DoesNotHaveTicket();
    error EventStorage__EventHasNotStarted();
    error EventStorage__EventHasEnded();
    error EventStorage__EventCannotStartBeforeCreation();
    error EventStorage__YouAlreadyHaveATicket();

    /////////////////////////////////////////////////////////////////////////
    // State variables
    /////////////////////////////////////////////////////////////////////////
    struct CreateEventInput {
        string name;
        string description;
        string location;
        uint256 startTime;
        uint256 endTime;
        string metaDataUri;
        uint256 price;
        string ticketBaseTokenUri;
        string ticketNFTName;
        string ticketNFTSymbol;
        string popBaseTokenUri;
        string popNFTName;
        string popNFTSymbol;
    }

    struct Event {
        uint256 id;
        string name;
        address eventCreator;
        string description;
        string location;
        uint256 startTime;
        uint256 endTime;
        string metaDataUri;
        uint256 price;
        string ticketUri;
        string popUri;
    }

    uint256 private s_eventId;
    mapping(uint256 => Event) private s_events;
    mapping(address => mapping(uint256 => bool)) private s_tickets;
    mapping(address => mapping(uint256 => bool)) private s_pops;
    TicketNFT immutable i_ticketNft;
    PoPNFT immutable i_popNft;

    /////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////
    event EventCreated(uint256 indexed id, string indexed name, address indexed eventCreator);

    /////////////////////////////////////////////////////////////////////////
    // Functions
    /////////////////////////////////////////////////////////////////////////
    constructor(
        string memory _ticketNFTName,
        string memory _ticketNFTSymbol,
        string memory _popNFTName,
        string memory _popNFTSymbol
    ) {
        s_eventId = 1;

        i_ticketNft = new TicketNFT(address(this), _ticketNFTName, _ticketNFTSymbol);
        i_popNft = new PoPNFT(address(this), _popNFTName, _popNFTSymbol);

        i_ticketNft.setEventManager(address(this));
        i_popNft.setEventManager(address(this));
    }

    /////////////////////////////////////////////////////////////////////////
    // External Functions
    /////////////////////////////////////////////////////////////////////////
    function createEvent(CreateEventInput memory input) external {
        if (s_events[s_eventId].id != 0) revert EventStorage__EventAlreadyExists();
        if (block.timestamp > input.startTime) revert EventStorage__EventCannotStartBeforeCreation();

        s_events[s_eventId] = Event({
            id: s_eventId,
            name: input.name,
            description: input.description,
            location: input.location,
            startTime: input.startTime,
            endTime: input.endTime,
            metaDataUri: input.metaDataUri,
            price: input.price,
            eventCreator: msg.sender,
            ticketUri: input.ticketBaseTokenUri,
            popUri: input.popBaseTokenUri
        });

        i_ticketNft.mint(msg.sender, s_eventId, input.ticketBaseTokenUri);
        s_tickets[msg.sender][s_eventId] = true;

        emit EventCreated(s_eventId, input.name, msg.sender);

        s_eventId++;
    }

    function buyTicket(uint256 eventId) external payable {
        Event memory ev = s_events[eventId];

        if (ev.id == 0) revert EventStorage__EventDoesNotExist();
        if (ev.price > msg.value) revert EventStorage__InsufficientFunds();
        if (block.timestamp > ev.endTime) revert EventStorage__EventHasEnded();
        if (s_tickets[msg.sender][eventId]) revert EventStorage__YouAlreadyHaveATicket();

        i_ticketNft.mint(msg.sender, eventId, ev.ticketUri);

        s_tickets[msg.sender][eventId] = true;
    }

    function saveAttendance(uint256 eventId) external {
        Event memory ev = s_events[eventId];

        if (ev.id == 0) revert EventStorage__EventDoesNotExist();
        if (!s_tickets[msg.sender][eventId]) revert EventStorage__DoesNotHaveTicket();
        if (block.timestamp < ev.startTime) revert EventStorage__EventHasNotStarted();
        if (block.timestamp > ev.endTime) revert EventStorage__EventHasEnded();

        i_popNft.mint(msg.sender, eventId, ev.popUri);

        s_pops[msg.sender][eventId] = true;
    }

    /////////////////////////////////////////////////////////////////////////
    // Getter Functions
    /////////////////////////////////////////////////////////////////////////
    function getEvent(uint256 eventId) external view returns (Event memory) {
        return s_events[eventId];
    }

    function getAllEvents() external view returns (Event[] memory) {
        if (s_eventId == 1) return new Event[](0);

        Event[] memory events = new Event[](s_eventId);
        uint256 count = 0;

        for (uint256 i = 1; i < s_eventId; i++) {
            Event memory ev = s_events[i];
            if (ev.id == 0) continue;

            events[count] = Event({
                id: ev.id,
                name: ev.name,
                eventCreator: ev.eventCreator,
                description: ev.description,
                location: ev.location,
                startTime: ev.startTime,
                endTime: ev.endTime,
                metaDataUri: ev.metaDataUri,
                price: ev.price,
                ticketUri: ev.ticketUri,
                popUri: ev.popUri
            });

            count++;
        }

        return events;
    }

    function getEventId() external view returns (uint256) {
        return s_eventId;
    }

    function getTicket(address user, uint256 eventId) external view returns (bool) {
        return s_tickets[user][eventId];
    }

    function getPop(address user, uint256 eventId) external view returns (bool) {
        return s_pops[user][eventId];
    }

    function getTicketNFT() external view returns (address) {
        return address(i_ticketNft);
    }

    function getPopNFT() external view returns (address) {
        return address(i_popNft);
    }
}
