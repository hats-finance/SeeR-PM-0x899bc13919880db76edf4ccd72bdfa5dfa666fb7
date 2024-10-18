# **SeeR-PM Audit Competition on Hats.finance** 


## Introduction to Hats.finance


Hats.finance builds autonomous security infrastructure for integration with major DeFi protocols to secure users' assets. 
It aims to be the decentralized choice for Web3 security, offering proactive security mechanisms like decentralized audit competitions and bug bounties. 
The protocol facilitates audit competitions to quickly secure smart contracts by having auditors compete, thereby reducing auditing costs and accelerating submissions. 
This aligns with their mission of fostering a robust, secure, and scalable Web3 ecosystem through decentralized security solutions​.

## About Hats Audit Competition


Hats Audit Competitions offer a unique and decentralized approach to enhancing the security of web3 projects. Leveraging the large collective expertise of hundreds of skilled auditors, these competitions foster a proactive bug hunting environment to fortify projects before their launch. Unlike traditional security assessments, Hats Audit Competitions operate on a time-based and results-driven model, ensuring that only successful auditors are rewarded for their contributions. This pay-for-results ethos not only allocates budgets more efficiently by paying exclusively for identified vulnerabilities but also retains funds if no issues are discovered. With a streamlined evaluation process, Hats prioritizes quality over quantity by rewarding the first submitter of a vulnerability, thus eliminating duplicate efforts and attracting top talent in web3 auditing. The process embodies Hats Finance's commitment to reducing fees, maintaining project control, and promoting high-quality security assessments, setting a new standard for decentralized security in the web3 space​​.

## SeeR-PM Overview

SeeR-PM is the next generation prediction market

## Competition Details


- Type: A public audit competition hosted by SeeR-PM
- Duration: 8 days
- Maximum Reward: $124,939.5
- Submissions: 144
- Total Payout: $13,743.35 distributed among 2 participants.

## Scope of Audit

## Project overview

Seer (see [paper](https://docs.google.com/document/d/10FhiWEEZt5P_fZUMJy9_yyLXGs9wMKInQEbsD2nALcc/edit#heading=h.iq5ucxossufh), note that this is a v1 and not everything in the paper is implemented) is a next generation prediction market.
It allows to take positions on future events and values.
You can read [the documentation](https://seer-3.gitbook.io/seer-documentation).

## Audit competition scope

The following contracts are in scope:
```
|-- contracts/src/
     |-- GnosisRouter.sol
     |-- MainnetRouter.sol
     |-- Market.sol
     |-- MarketFactory.sol
     |-- RealityProxy.sol
     |-- Router.sol
```

## Interaction contracts

The following contracts are contracts already deployed by third parties that Seer is interacting with. Reviewers are advised to read those contracts in order to understand the way Seer contracts are interacting with them.
They are not "in scope" unless an issue with one of those contract can lead to an issue with Seer (even if "out of scope", if you find an issue, we'll help you report it to its respective project).

```
|-- contracts/src/
     |-- interaction/
         |-- 1155-to-20/
             |-- Wrapped1155Factory.sol
         |-- conditional-tokens/
             |-- ConditionalTokens.sol
         |-- reality/
             |-- RealityETH-3.0.sol
         |-- sDAI-on-Gnosis/
             |-- periphery/
                 |-- SavingsXDaiAdapter.sol
```

## Sample deployement

In order to make it easier for hunter to understand how contracts are deployed and pointing to each others, we made a sample deployment on Gnosis Chain:

*  GnosisRouter:[0xf68fF43B643Df752132463AA1dBc9c75D7349D07](https://gnosisscan.io/address/0xf68fF43B643Df752132463AA1dBc9c75D7349D07#code)
* Market:[0x8F76bC35F8C72E5e2Ec55ebED785da5efaa9636a](https://gnosisscan.io/address/0x8F76bC35F8C72E5e2Ec55ebED785da5efaa9636a)
* MarketFactory:[0x47fc00bbFC6DCFB64f33405517E65CA9293a78FB](https://gnosisscan.io/address/0x47fc00bbFC6DCFB64f33405517E65CA9293a78FB)
* MarketView:[0x995dC9c89B6605a1E8cc028B37cb8e568e27626f](https://gnosisscan.io/address/0x995dC9c89B6605a1E8cc028B37cb8e568e27626f)
* RealityProxy:[0xc260ADfAC11f97c001dC143d2a4F45b98e0f2D6C](https://gnosisscan.io/address/0xc260ADfAC11f97c001dC143d2a4F45b98e0f2D6C)
 
You are allowed to test and interact on those contracts.
You can look at [the frontend](https://seer-pm.netlify.app/) too.

## Medium severity issues


- **Potential Denial of Service via Token Redemption Front-Running Exploit**

  An exploitable vulnerability exists in a token redemption process that could lead to Denial of Service (DOS) and Gas Griefing attacks. Attackers can disrupt a user's attempt to redeem tokens by inserting a small amount of tokens into the user's balance, causing redemption transactions to fail and waste gas. The issue stems from a process where the contract iterates over outcomeIndexes to calculate and transfer token balances, without accounting for potential manipulation of these balances. This could particularly affect smart contracts and wallets integrating with platforms that perform exact token approvals, thus rendering them unusable. The suggested solution involves modifying the redemption function to accept exact token amounts, preventing recalculation and potential manipulation on-chain. The exploit could lead to substantial operational disruption, although it was previously considered medium severity due to the perception of users being able to circumvent it by approving a higher token amount.


  **Link**: [Issue #82](https://github.com/hats-finance/SeeR-PM-0x899bc13919880db76edf4ccd72bdfa5dfa666fb7/issues/82)

## Low severity issues


- **ERC20 Non-Compliance Causes Token Transfer Failures in `Router` Contract**

  The `Router` contract's functions `mergePositions()` and `redeemPositions()` utilize `transfer` and `transferFrom()` to move `collateralToken`. These will fail for non-reverting tokens that return false on transfer failure, like the EURS stablecoin. The recommended solution is implementing OpenZeppelin's `SafeERC20` to handle such token transaction issues properly, ensuring user's funds are not inadvertently lost.


  **Link**: [Issue #103](https://github.com/hats-finance/SeeR-PM-0x899bc13919880db76edf4ccd72bdfa5dfa666fb7/issues/103)



## Conclusion

The Hats.finance audit competition for SeeR-PM showcased a decentralized and proactive approach to securing web3 projects through competitive auditing. This model leverages the expertise of numerous skilled auditors, encouraging them to identify vulnerabilities prior to project launches. The competition, characterized by its time-based and results-driven nature, only rewards successful auditors, efficiently managing its budget by paying only for identified issues and retaining funds if none are found. The audit of SeeR-PM involved a thorough examination of various smart contracts but resulted in identifying only a few issues: a medium-severity denial of service vulnerability related to token redemption, and a low-severity issue concerning ERC20 token compliance affecting the Router contract. These findings reflect the competition's commitment to maintaining rigorous security standards while promoting decentralized, high-quality security assessments, effectively reducing costs and setting a new benchmark for web3 project security.

## Disclaimer


This report does not assert that the audited contracts are completely secure. Continuous review and comprehensive testing are advised before deploying critical smart contracts.


The SeeR-PM audit competition illustrates the collaborative effort in identifying and rectifying potential vulnerabilities, enhancing the overall security and functionality of the platform.


Hats.finance does not provide any guarantee or warranty regarding the security of this project. Smart contract software should be used at the sole risk and responsibility of users.

