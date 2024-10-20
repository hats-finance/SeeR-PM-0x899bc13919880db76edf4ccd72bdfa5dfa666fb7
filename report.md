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


- **Potential Denial of Service in Token Redemption Process**

  An identified vulnerability could allow attackers to execute a Denial of Service (DOS) or Gas Griefing attack during the token redemption process. When redeeming tokens, the system calculates balances by iterating over a list of indices. This approach can be disrupted if an attacker front-runs the process by sending a small token amount, which alters the balance calculation and leads to transaction reversion. This exploit can result in transaction failures, wasting users' gas fees, and hindering the redemption process. Users aiming to approve exact token amounts might face continuous transaction failures due to this exploitation. To counteract this, the redemption function should be altered to accept precise token amounts for each index, preventing balance manipulation.


  **Link**: [Issue #82](https://github.com/hats-finance/SeeR-PM-0x899bc13919880db76edf4ccd72bdfa5dfa666fb7/issues/82)

## Low severity issues


- **Potential Transfer Failure in Router Contract for Non-compliant ERC20 Tokens**

  The `Router` contract includes functions that use `transfer` and `transferFrom` to handle tokens, which can fail silently for certain non-compliant ERC20 tokens like EURS. This can lead to unacknowledged failed transactions and a loss of funds for users. It's suggested to use OpenZeppelin's `SafeERC20` to handle these cases properly by checking the return value of token transfers.


  **Link**: [Issue #103](https://github.com/hats-finance/SeeR-PM-0x899bc13919880db76edf4ccd72bdfa5dfa666fb7/issues/103)



## Conclusion

The audit competition hosted by Hats.finance for SeeR-PM highlighted key areas in improving the security and efficiency of Web3 applications. Hats.finance facilitates such audits through a decentralized, competitive environment that engages top auditors in finding potential vulnerabilities before project launches. This method ensures quality results while managing costs through a pay-for-results system, rewarding only successful audit submissions. The SeeR-PM audit was public, conducted over eight days with a maximum reward of $124,939.5, but ultimately resulted in a total payout of $13,743.35 to two contributors. Key vulnerabilities found included a medium severity issue related to potential denial of service during token redemption and a low severity issue regarding token transfer failures for non-compliant tokens. Recommendations to enhance security included modifying token redemption processes and utilizing OpenZeppelin's SafeERC20 for more robust transaction handling. The SeeR-PM audit represents a critical step towards strengthening decentralized security standards in the rapidly evolving Web3 space.

## Disclaimer


This report does not assert that the audited contracts are completely secure. Continuous review and comprehensive testing are advised before deploying critical smart contracts.


The SeeR-PM audit competition illustrates the collaborative effort in identifying and rectifying potential vulnerabilities, enhancing the overall security and functionality of the platform.


Hats.finance does not provide any guarantee or warranty regarding the security of this project. Smart contract software should be used at the sole risk and responsibility of users.

