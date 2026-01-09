// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TokenFactoryRegistry} from "../src/TokenFactoryRegistry.sol";
import {ERC20Factory} from "../src/factories/ERC20Factory.sol";
import {ERC721Factory} from "../src/factories/ERC721Factory.sol";
import {ERC1155Factory} from "../src/factories/ERC1155Factory.sol";

/**
 * @title DeployTokenFactory
 * @author Dewiz
 * @notice Deployment script for the complete Token Factory infrastructure
 * @dev Deploys all factory contracts and registers them with the central registry
 */
contract DeployTokenFactory is Script {
    TokenFactoryRegistry public registry;
    ERC20Factory public erc20Factory;
    ERC721Factory public erc721Factory;
    ERC1155Factory public erc1155Factory;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Token Factory infrastructure...");
        console.log("Deployer address:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the central registry
        registry = new TokenFactoryRegistry(deployer);
        console.log("TokenFactoryRegistry deployed at:", address(registry));

        // Deploy individual factories
        erc20Factory = new ERC20Factory(deployer);
        console.log("ERC20Factory deployed at:", address(erc20Factory));

        erc721Factory = new ERC721Factory(deployer);
        console.log("ERC721Factory deployed at:", address(erc721Factory));

        erc1155Factory = new ERC1155Factory(deployer);
        console.log("ERC1155Factory deployed at:", address(erc1155Factory));

        // Register all factories with the registry
        registry.registerAllFactories(
            address(erc20Factory),
            address(erc721Factory),
            address(erc1155Factory)
        );
        console.log("All factories registered with registry");

        vm.stopBroadcast();

        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("Registry:       ", address(registry));
        console.log("ERC20 Factory:  ", address(erc20Factory));
        console.log("ERC721 Factory: ", address(erc721Factory));
        console.log("ERC1155 Factory:", address(erc1155Factory));
    }
}

/**
 * @title DeployTokenFactoryLocal
 * @notice Deployment script for local development (Anvil)
 * @dev Uses default Anvil private key for testing
 */
contract DeployTokenFactoryLocal is Script {
    TokenFactoryRegistry public registry;
    ERC20Factory public erc20Factory;
    ERC721Factory public erc721Factory;
    ERC1155Factory public erc1155Factory;

    // Default Anvil account #0 private key
    uint256 constant ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function run() public {
        address deployer = vm.addr(ANVIL_PRIVATE_KEY);

        console.log("Deploying Token Factory infrastructure (LOCAL)...");
        console.log("Deployer address:", deployer);

        vm.startBroadcast(ANVIL_PRIVATE_KEY);

        // Deploy the central registry
        registry = new TokenFactoryRegistry(deployer);
        console.log("TokenFactoryRegistry deployed at:", address(registry));

        // Deploy individual factories
        erc20Factory = new ERC20Factory(deployer);
        console.log("ERC20Factory deployed at:", address(erc20Factory));

        erc721Factory = new ERC721Factory(deployer);
        console.log("ERC721Factory deployed at:", address(erc721Factory));

        erc1155Factory = new ERC1155Factory(deployer);
        console.log("ERC1155Factory deployed at:", address(erc1155Factory));

        // Register all factories with the registry
        registry.registerAllFactories(
            address(erc20Factory),
            address(erc721Factory),
            address(erc1155Factory)
        );
        console.log("All factories registered with registry");

        vm.stopBroadcast();

        console.log("");
        console.log("=== Local Deployment Summary ===");
        console.log("Registry:       ", address(registry));
        console.log("ERC20 Factory:  ", address(erc20Factory));
        console.log("ERC721 Factory: ", address(erc721Factory));
        console.log("ERC1155 Factory:", address(erc1155Factory));
    }
}
