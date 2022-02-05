// SPDX-License-Identifier: MIT

/*
    basic campaign/fund raising smart contract
    vote counter based on how many times you contribute
    (3 times contribution with minimum amount still count as 3 votes,
    while 1 time contribution with 3x of minimum amount counts as 1 vote)
*/

pragma solidity ^0.8.0;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint min) public {
        Campaign newCampaign = new Campaign(min, msg.sender);
        deployedCampaigns.push(address(newCampaign));
    }

    function getDeployedCampaigns() public view returns(address[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;
    address public manager;
    uint public minContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;
    uint public numCreated;
    address[] public allaccount;

    modifier onlyOwner() {
        require(msg.sender == manager);
        _;
    }

    constructor(uint min, address creator) {
        manager = creator;
        minContribution = min;
    }

    function contribute() public payable {
        require(msg.value >= minContribution);
        approvers[msg.sender] = true;
        approversCount++;
        allaccount.push(msg.sender);
    }

    function createRequest(string memory description,uint value, address payable recipient) public onlyOwner {
        Request storage newRequest = requests[numCreated];
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;
        numCreated++;
    }

    function approveRequests(uint index) public {
        Request storage request = requests[index];
        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint index) public onlyOwner {
        Request storage request = requests[index];
        require(request.approvalCount > (approversCount/2));
        require(!request.complete);

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns (
        uint, uint, uint, uint, address
    ) {
        return (
            minContribution,
            address(this).balance,
            requests.length,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns(uint) {
        return numCreated;
    }

    function accountList() public view returns(address[] memory) {
        return allaccount;
    }
}