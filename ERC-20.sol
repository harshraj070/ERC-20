// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

contract MyToken is ERC20, ERC20Burnable, ERC20Permit, Ownable, Pausable, ERC20Snapshot {
    uint256 private _totalSupply = 1000000 * 10 ** decimals();
    mapping(address => bool) private _blacklist;
    address public taxRecipient;
    uint256 public taxPercentage;

    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _mint(msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        require(!_blacklist[msg.sender], "Sender is blacklisted");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        uint256 taxAmount = (amount * taxPercentage) / 100;
        uint256 amountAfterTax = amount - taxAmount;

        _transfer(msg.sender, taxRecipient, taxAmount);
        return super.transfer(recipient, amountAfterTax);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        require(!_blacklist[sender], "Sender is blacklisted");
        require(balanceOf(sender) >= amount, "Sender does not have enough tokens");

        uint256 taxAmount = (amount * taxPercentage) / 100;
        uint256 amountAfterTax = amount - taxAmount;

        _transfer(sender, taxRecipient, taxAmount);
        return super.transferFrom(sender, recipient, amountAfterTax);
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        return super.approve(spender, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return super.allowance(owner, spender);
    }

    function burn(uint256 amount) public override {
        _burn(msg.sender, amount);
        _totalSupply -= amount;
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
        _totalSupply += amount;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function setTaxRecipient(address _taxRecipient) public onlyOwner {
        taxRecipient = _taxRecipient;
    }

    function setTaxPercentage(uint256 _taxPercentage) public onlyOwner {
        require(_taxPercentage <= 100, "Tax percentage cannot exceed 100");
        taxPercentage = _taxPercentage;
    }

    function blacklist(address account) public onlyOwner {
        _blacklist[account] = true;
    }

    function removeFromBlacklist(address account) public onlyOwner {
        _blacklist[account] = false;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function freezeAccount(address account, bool freeze) public onlyOwner {
        _blacklist[account] = freeze;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
