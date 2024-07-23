// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecureDeal is ReentrancyGuard {
    struct Deal {
        address client;
        address developer;
        uint currentMilestone; // 当前里程碑数
        uint totalMilestones;  // 总里程碑数
        uint amountPerMilestone; // 每个里程碑的付款金额
        bool refunded; // 是否已退款
    }

    struct DealDetail {
        uint256 total;    // 总金额
        uint256 withdrawn; // 已提走的金额（包括释放的付款和退款）
    }

    uint256 public dealCount; // 交易数量
    mapping(uint256 => Deal) public deals;
    mapping(uint256 => DealDetail) public dealDetails;

    // 创建交易时发送的事件
    event DealCreated(uint256 dealId, address client, address developer, uint totalMilestones, uint amountPerMilestone);
    event PaymentReleased(uint256 dealId, uint currentMilestone);
    event DealRefunded(uint256 dealId, address client, uint256 amount);

    // 创建交易
    function createDeal(address _developer, uint _totalMilestones, uint _amountPerMilestone) public payable returns(uint256) {
        require(msg.value == _amountPerMilestone * _totalMilestones, "Incorrect payment amount");

        deals[dealCount] = Deal({
            client: msg.sender,
            developer: _developer,
            currentMilestone: 0,
            totalMilestones: _totalMilestones,
            amountPerMilestone: _amountPerMilestone,
            refunded: false
        });

        dealDetails[dealCount] = DealDetail({
            total: msg.value,
            withdrawn: 0
        });

        emit DealCreated(dealCount, msg.sender, _developer, _totalMilestones, _amountPerMilestone);
        dealCount++;
        return dealCount - 1;
    }

    // 释放付款
    function releasePayment(uint _dealId) public nonReentrant {
        Deal storage deal = deals[_dealId];
        DealDetail storage detail = dealDetails[_dealId];

        require(msg.sender == deal.client, "Only client can release payment");
        require(deal.currentMilestone < deal.totalMilestones, "All milestones have been paid");
        require(!deal.refunded, "Deal has been refunded");

        uint256 paymentAmount = deal.amountPerMilestone;
        require(detail.total >= detail.withdrawn + paymentAmount, "Insufficient funds in deal");

        deal.currentMilestone++;
        detail.withdrawn += paymentAmount;

        // 在转账之前更新状态，以防止重入攻击
        payable(deal.developer).transfer(paymentAmount);

        emit PaymentReleased(_dealId, deal.currentMilestone);
    }

    // 退款给客户
    function refundClient(uint256 _dealId) public nonReentrant {
        Deal storage deal = deals[_dealId];
        DealDetail storage detail = dealDetails[_dealId];

        require(msg.sender == deal.developer, "Only developer can initiate refund");
        require(!deal.refunded, "Deal has already been refunded");
        require(deal.currentMilestone < deal.totalMilestones, "Milestones have been completed");

        uint256 refundAmount = (deal.totalMilestones - deal.currentMilestone) * deal.amountPerMilestone;
        require(detail.total >= detail.withdrawn + refundAmount, "Insufficient funds in deal");

        deal.refunded = true; // 标记为已退款
        detail.withdrawn += refundAmount;

        // 在转账之前更新状态，以防止重入攻击
        payable(deal.client).transfer(refundAmount);

        emit DealRefunded(_dealId, deal.client, refundAmount);
    }

    // 获取合约余额
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // 获取交易详情
    function getDealDetail(uint256 _dealId) public view returns (uint256 total, uint256 withdrawn) {
        DealDetail storage detail = dealDetails[_dealId];
        return (detail.total, detail.withdrawn);
    }
}