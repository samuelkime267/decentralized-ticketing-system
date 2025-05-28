// SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {EventStorage} from "../src/EventStorage.sol";

contract DeployEventStorage is Script {
    function run() external returns (EventStorage) {
        (
            string memory ticketNFTName,
            string memory ticketNFTSymbol,
            string memory popNFTName,
            string memory popNFTSymbol
        ) = helper();

        vm.startBroadcast();
        EventStorage eventStorage = new EventStorage(ticketNFTName, ticketNFTSymbol, popNFTName, popNFTSymbol);
        vm.stopBroadcast();

        return eventStorage;
    }

    function helper()
        public
        pure
        returns (
            string memory ticketNFTName,
            string memory ticketNFTSymbol,
            string memory popNFTName,
            string memory popNFTSymbol
        )
    {
        ticketNFTName = "Ticket NFT";
        ticketNFTSymbol = "TICKET";
        popNFTName = "PoP NFT";
        popNFTSymbol = "POP";
    }
}
