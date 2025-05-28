// SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TicketNFT is ERC721, ERC721URIStorage, Ownable {
    /////////////////////////////////////////////////////////////////////////
    // Errors
    /////////////////////////////////////////////////////////////////////////
    error TicketNFT__NotEventManager();

    /////////////////////////////////////////////////////////////////////////
    // State variables
    /////////////////////////////////////////////////////////////////////////
    uint256 private s_tokenIdCounter;
    mapping(uint256 => uint256) private s_tokenIdToEventId;
    mapping(uint256 => string) private s_tokenIdTokenURIs;
    address private s_eventManager;

    /////////////////////////////////////////////////////////////////////////
    // Functions
    /////////////////////////////////////////////////////////////////////////
    constructor(address _initialOwner, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        Ownable(_initialOwner)
    {
        s_tokenIdCounter = 1;
    }

    /////////////////////////////////////////////////////////////////////////
    // Public Functions
    /////////////////////////////////////////////////////////////////////////
    function mint(address _to, uint256 _eventId, string memory _tokenUri) external onlyEventManager {
        _mint(_to, s_tokenIdCounter);
        s_tokenIdTokenURIs[s_tokenIdCounter] = _tokenUri;
        s_tokenIdToEventId[s_tokenIdCounter] = _eventId;
        s_tokenIdCounter++;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return s_tokenIdTokenURIs[tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /////////////////////////////////////////////////////////////////////////
    // External Functions
    /////////////////////////////////////////////////////////////////////////
    function setEventManager(address _manager) external onlyOwner {
        s_eventManager = _manager;
    }

    /////////////////////////////////////////////////////////////////////////
    // Getter Functions
    /////////////////////////////////////////////////////////////////////////
    function getTokenIdCounter() external view returns (uint256) {
        return s_tokenIdCounter;
    }

    function getEventManager() external view returns (address) {
        return s_eventManager;
    }

    function getEventId(uint256 tokenId) external view returns (uint256) {
        return s_tokenIdToEventId[tokenId];
    }

    /////////////////////////////////////////////////////////////////////////
    // Modifiers
    /////////////////////////////////////////////////////////////////////////
    modifier onlyEventManager() {
        if (msg.sender != s_eventManager) revert TicketNFT__NotEventManager();
        _;
    }
}
