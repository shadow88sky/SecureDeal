// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SecureDeal.sol";

contract SecureDealTest is Test {
    SecureDeal secureDeal;
    address client = address(0x2);
    address developer = address(0x3);

    function setUp() public {
        secureDeal = new SecureDeal();
    }

    function testCreateDeal() public {
        uint totalMilestones = 3;
        uint amountPerMilestone = 1 ether;
        uint totalPayment = totalMilestones * amountPerMilestone;

        vm.deal(client, totalPayment);
        vm.prank(client);
        uint dealId = secureDeal.createDeal{value: totalPayment}(developer, totalMilestones, amountPerMilestone);

        (uint256 total, uint256 withdrawn) = secureDeal.getDealDetail(dealId);
        assertEq(total, totalPayment);
        assertEq(withdrawn, 0);
    }

    function testReleasePayment() public {
        uint totalMilestones = 3;
        uint amountPerMilestone = 1 ether;
        uint totalPayment = totalMilestones * amountPerMilestone;

        vm.deal(client, totalPayment);
        vm.prank(client);
        uint dealId = secureDeal.createDeal{value: totalPayment}(developer, totalMilestones, amountPerMilestone);

        vm.prank(client);
        secureDeal.releasePayment(dealId);

        (, uint256 withdrawn) = secureDeal.getDealDetail(dealId);
        assertEq(withdrawn, amountPerMilestone);
    }

    function testRefundClient() public {
 
        uint totalMilestones = 3;
        uint amountPerMilestone = 1 ether;
        uint totalPayment = totalMilestones * amountPerMilestone;

        vm.deal(client, totalPayment);
        vm.prank(client);
        uint dealId = secureDeal.createDeal{value: totalPayment}(developer, totalMilestones, amountPerMilestone);

        vm.prank(client);
        secureDeal.releasePayment(dealId);

        vm.prank(developer);
        secureDeal.refundClient(dealId);

        (uint256 total, uint256 withdrawn) = secureDeal.getDealDetail(dealId);
        assertEq(withdrawn, total);

        assertEq(address(secureDeal).balance, 0);
        assertEq(address(client).balance, totalPayment - amountPerMilestone);
    }
}