// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public cryptoDevTokenAddress;

    // Exchange is inheriting ERC20, because our exchange would keep track of Crypto Dev LP tokens
    constructor(address _CryptoDevtoken) ERC20("CryptoDev LP Token", "CDLP") {
        require(
            _CryptoDevtoken != address(0),
            "Token address passed is a null address"
        );
        cryptoDevTokenAddress = _CryptoDevtoken;
    }

    /**
     * @dev Returns the amount of `Crypto Dev Tokens` held by the contract
     */
    function getReserve() public view returns (uint256) {
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Adds liquidity to the exchange.
     */
    function addLiquidity(uint256 tokenAmount) public payable returns (uint256) {
        uint256 liquidityTokenAmount;
        uint256 ethBalance = address(this).balance;
        uint256 cryptoDevTokenReserve = getReserve();
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);

        // check if the user is capable of transfering such amount of tokens
        require(
            cryptoDevToken.balanceOf(msg.sender) >= tokenAmount,
            "You don't have enough tokens"
        );
        if (cryptoDevTokenReserve == 0) {
            cryptoDevToken.transferFrom(msg.sender, address(this), tokenAmount);

            //if the pool is empty, the ratio is set by the first to add liquidity
            //the user receives liquiditytokens in the same amount as the Eth available in the pool
            liquidityTokenAmount = ethBalance;
            _mint(msg.sender, liquidityTokenAmount);
        } else {
            /*
            If the reserve is not empty, intake any user supplied value for
            `Ether` and determine according to the ratio how many `Crypto Dev` tokens
            need to be supplied to prevent any large price impacts because of the additional
            liquidity
        */
            // EthReserve should be the current ethBalance subtracted by the value of ether sent by the user
            // in the current `addLiquidity` call
            uint256 ethReserve = ethBalance - msg.value;
            uint256 cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve) /
                ethReserve;
            require(
                tokenAmount >= cryptoDevTokenAmount,
                "You must add more CD to match the liquidity ratio"
            );
            cryptoDevToken.transferFrom(
                msg.sender,
                address(this),
                cryptoDevTokenAmount
            );
            // The amount of LP tokens that would be sent to the user should be propotional to the liquidity of
            // ether added by the user
            // Ratio here to be maintained is ->
            // (LP tokens to be sent to the user (liquidity)/ totalSupply of LP tokens in contract) = (Eth sent by the user)/(Eth reserve in the contract)
            liquidityTokenAmount = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidityTokenAmount);
        }

        return liquidityTokenAmount;
    }

    /**
    * @dev function that recieves LP tokens and returns the user's share of the pool
    Returns the amount Eth/Crypto Dev tokens that would be returned to the user
    * in the swap
    */
    function removeLiquidity(uint256 tokenAmount)
        public
        returns (uint256, uint256)
    {
        require(tokenAmount > 0, "tokenAmount should be greater than zero");
        require(
            balanceOf(msg.sender) >= tokenAmount,
            "User can not retrieve more tokens than what is owned"
        );
        uint256 ethReserve = address(this).balance;
        //calculates user's eth share
        uint256 ethAmount = (ethReserve * tokenAmount) / (totalSupply());
        //calculates user's CD sahre
        uint256 cryptoDevTokenAmount = (getReserve() * tokenAmount) / (totalSupply());
        (bool sent, ) = msg.sender.call{value: ethAmount}("");
        require(sent, "Failed to send Ether");
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
        //burns used LP tokens
        _burn(msg.sender, tokenAmount);
        return (ethAmount, cryptoDevTokenAmount);
    }

    /**
* @dev Returns the amount Eth/Crypto Dev tokens that would be returned to the user
* in the swap
*/
function getAmountOfTokens(
    uint256 inputAmount,
    uint256 inputReserve,
    uint256 outputReserve
) public pure returns (uint256) {
    require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
     // We are charging a fee of `1%`
    // Input amount with fee = (input amount - (1*(input amount)/100)) = ((input amount)*99)/100
    uint256 inputAmountWithFee = (inputAmount * 99)/100;
    uint256 outputAmount = (inputAmountWithFee * outputReserve)/(inputReserve + inputAmountWithFee);
    return outputAmount;
}

/**
* @dev Swaps Eth for CryptoDev Tokens
* @param minTokens - a minimal accepted amount for the transaction
*/
function ethToCryptoDevToken(uint256 minTokens) public payable {
    uint256 tokenReserve = getReserve();
    uint256 tokensBought = getAmountOfTokens(msg.value, address(this).balance - msg.value, tokenReserve);

    require(tokensBought >= minTokens, "Insufficient output amount");
    ERC20(cryptoDevTokenAddress).transfer(msg.sender, tokensBought);
}
/**
* @dev Swaps CryptoDev Tokens for Eth
* @param minEth - a minimal accepted amount for the transaction
*/
function cryptoDevTokenToEth(uint tokensSold, uint minEth) public {
    require(ERC20(cryptoDevTokenAddress).balanceOf(msg.sender) >= tokensSold, "Not enough tokens to sell");
    uint256 tokenReserve = getReserve();

    uint256 ethBought = getAmountOfTokens(tokensSold, tokenReserve, address(this).balance);

    require(ethBought >= minEth, "Insufficient output amount");

    ERC20(cryptoDevTokenAddress).transferFrom(msg.sender, address(this), tokensSold);

    (bool sent, ) = msg.sender.call{value: ethBought}("");
        require(sent, "Failed to send Ether");

}
}
