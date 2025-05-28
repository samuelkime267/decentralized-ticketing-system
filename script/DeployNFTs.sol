// SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {TicketNFT} from "../src/TicketNFT.sol";
import {PoPNFT} from "../src/PoPNFT.sol";

contract DeployNFTs is Script {
    function run(address _owner) external returns (TicketNFT, PoPNFT) {
        (
            string memory ticketNFTName,
            string memory ticketNFTSymbol,
            string memory popNFTName,
            string memory popNFTSymbol
        ) = helper();

        vm.startBroadcast();
        TicketNFT ticketNft = new TicketNFT(_owner, ticketNFTName, ticketNFTSymbol);
        PoPNFT popNft = new PoPNFT(_owner, popNFTName, popNFTSymbol);
        vm.stopBroadcast();

        return (ticketNft, popNft);
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
