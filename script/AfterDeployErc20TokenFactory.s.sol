// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TokenFactoryRegistry} from "../src/TokenFactoryRegistry.sol";
import {ERC20Factory} from "../src/factories/ERC20Factory.sol";
import {DewizERC20} from "../src/tokens/DewizERC20.sol";

/**
 * @title AfterDeployErc20TokenFactory
 * @author Dewiz
 * @notice Post-deployment script in publics blockchains for ERC-20 Factory setup and verification
 * @dev Performs additional configuration and verification steps after deploying the ERC-20 Factory
 */
contract AfterDeployErc20TokenFactory is Script {
    TokenFactoryRegistry public registry;
    ERC20Factory public erc20Factory; 
    DewizERC20 public sampleToken;

    function run() public { 

      uint256 timestamp = block.timestamp;
      string memory timestampStr = vm.toString(timestamp);
      string memory tokenName = string.concat("Dewiz Token (DWZ-", timestampStr, ")");
      string memory tokenSymbol = string.concat("DWZ-", timestampStr);

      address sampleTokenAddress = erc20Factory.createSimpleToken(
          tokenName,
          tokenSymbol,
          1000000 * 10 ** 2
      );
      sampleToken = DewizERC20(sampleTokenAddress);
      console.log("Additional verification. Checking token properties");
      console.log("Sample Dewiz ERC-20 token created at:", address(sampleToken));
      console.log("Token name:", sampleToken.name());
      console.log("Token symbol:", sampleToken.symbol());
      console.log("Token decimals:", sampleToken.decimals());
      console.log("Token total supply:", sampleToken.totalSupply());

    }

    function setUp() public {
      uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
      address deployer = vm.addr(deployerPrivateKey);

      // Initialize contract instances with known addresses
      // Failover values come from Base Sepolia testnet deployment
      address erc20FactoryAddress = vm.envOr("ERC20_FACTORY_ADDRESS", address(0xD4D8fb16d184977ae4c04A823D32134853C72B7a));
      address registryAddress = vm.envOr("REGISTRY_ADDRESS", address(0x79b135Cd75D7c729905Cf02aeB1B4e7D09f0Cf3D));
      registry = TokenFactoryRegistry(registryAddress);
      erc20Factory = ERC20Factory(erc20FactoryAddress);

      console.log("Setting up post-deployment configuration...");
      console.log("Deployer address:", deployer);
      console.log("ERC20 Factory address:", erc20FactoryAddress);
      console.log("Registry address:", registryAddress);
      
    }

    function setupTestnetInCaseOfNullAddresses() public {
      if (address(registry) == address(0) || address(erc20Factory) == address(0)) {
        console.log("One or more contract addresses are null. Setting up testnet configuration...");
        console.log("This is a placeholder for Base testnet setup logic.");
        address erc20FactoryAddress = 0xD4D8fb16d184977ae4c04A823D32134853C72B7a;
        address registryAddress = 0x79b135Cd75D7c729905Cf02aeB1B4e7D09f0Cf3D;
        registry = TokenFactoryRegistry(registryAddress);
        erc20Factory = ERC20Factory(erc20FactoryAddress);
        // Set up testnet configuration here (e.g., using hardcoded addresses or deploying mocks)
        // This is a placeholder and should be replaced with actual logic to handle testnet setup
      } else {
        console.log("All contract addresses are valid. No testnet setup needed.");
      }
    }
}