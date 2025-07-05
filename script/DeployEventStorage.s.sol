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

/**
 * forge script script/DeployEventStorage.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
 */
