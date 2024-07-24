// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/SecureDeal.sol";

contract DeployAnvil is Script {
    function run() external {
        // 获取部署者的私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署合约
        SecureDeal secureDeal = new SecureDeal();

        // 输出合约地址
        console.log("SecureDeal deployed to:", address(secureDeal));

        vm.stopBroadcast();
    }
}