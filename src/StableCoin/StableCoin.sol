// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {AggregatorV3Interface} from "@chainlink/contracts@1.1.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Permit.sol";
import {KeeperCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED
 * VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * If you are reading data feeds on L2 networks, you must
 * check the latest answer from the L2 Sequencer Uptime
 * Feed to ensure that the data is accurate in the event
 * of an L2 sequencer outage. See the
 * https://docs.chain.link/data-feeds/l2-sequencer-feeds
 * page for details.
 */

contract StableCoin is ERC20, Ownable, ERC20Permit, KeeperCompatibleInterface {
    AggregatorV3Interface internal dataFeed;
    mapping(address => uint256) public _ethValut;
    mapping(address => uint256) public _linkValut;

    event Deposit(uint256 depositValue);

    uint256 public counter;
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    constructor(
        address initialOwner,
        uint256 updateInterval
    )
        payable
        ERC20("StableCoin", "USDR")
        Ownable(initialOwner)
        ERC20Permit("StableCoin")
    {
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        counter = 0;
    }

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();

        return answer;
    }

    function mintCoin(
        address to,
        uint256 amount
    ) public payable onlyOwner returns (uint256) {
        // ETH/USD 환율을 얻어옴
        uint256 ethUsdRate = uint256(getChainlinkDataFeedLatestAnswer());

        // 사용자가 보낸 wei 금액
        uint256 weiAmount = msg.value;

        // wei 금액을 USD로 변환한 후, 코인을 민팅할 양 계산
        uint256 amountToMint = (weiAmount * ethUsdRate) / 1e18;
        uint256 coinAmount = amountToMint / 1e8;

        // 민팅된 코인의 양을 이벤트로 기록
        emit Deposit(coinAmount);

        // 민팅된 코인의 양을 사용자에게 반환
        return amountToMint;
    }

    receive() external payable {}

    fallback() external payable {}

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getETHValutBalance(address account) public view returns (uint256) {
        return _ethValut[account];
    }

    function getLINKValutBalance(
        address account
    ) public view returns (uint256) {
        return _linkValut[account];
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = bytes("");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        // add some verification
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Time interval not met");

        lastTimeStamp = block.timestamp;
    }
}
