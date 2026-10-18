// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

/// A deliberately broken vault used as the engine's calibration fixture.
/// Ground truth is recorded in examples/vulnvault/GROUND_TRUTH.md.
contract VulnVault {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public shares;
    uint256 public totalShares;
    address public owner;
    IERC20 public token;

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
    }

    // BUG 1 - reentrancy: external call before state update.
    function withdrawAll() external {
        uint256 amount = deposits[msg.sender];
        require(amount > 0, "nothing to withdraw");
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "send failed");
        deposits[msg.sender] = 0;
    }

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
    }

    // BUG 2 - share price read from a live balance an attacker can donate into.
    function depositToken(uint256 amount) external {
        uint256 bal = token.balanceOf(address(this));
        uint256 minted = totalShares == 0 ? amount : (amount * totalShares) / bal;
        token.transferFrom(msg.sender, address(this), amount);
        shares[msg.sender] += minted;
        totalShares += minted;
    }

    // BUG 3 - no access control. Anyone drains the contract.
    function sweep(address to) external {
        payable(to).transfer(address(this).balance);
    }

    // BUG 4 - return value ignored; a non-reverting false leaves shares burned
    // without paying out.
    function redeem(uint256 amt) external {
        require(shares[msg.sender] >= amt, "insufficient shares");
        shares[msg.sender] -= amt;
        totalShares -= amt;
        token.transfer(msg.sender, amt);
    }

    // CONTROL - this one is correct. Flagging it is a false positive.
    function setOwner(address newOwner) external {
        require(msg.sender == owner, "not owner");
        require(newOwner != address(0), "zero address");
        owner = newOwner;
    }

    receive() external payable {
        deposits[msg.sender] += msg.value;
    }
}
