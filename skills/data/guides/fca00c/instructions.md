# Instructions <!-- omit in toc -->

> For Facilitator or Organizer Role

## Table of Contents <!-- omit in toc -->

- [Before the Event](#before-the-event)
  - [Tools You Will Use](#tools-you-will-use)
  - [Complete the Following](#complete-the-following)
- [During the Event](#during-the-event)
  - [Gameplay for Quest 1](#gameplay-for-quest-1)
  - [Gameplay for Quests 2-6](#gameplay-for-quests-2-6)

## Before the Event

You are embarking on a journey of Smart contract mastery with Stellar Quest 3, an interactive learning game designed to ignite your understanding and empower you to build sophisticated smart contracts.

### Tools You Will Use

- [Stellar CLI](https://developers.stellar.org/docs/tools/cli): Build, deploy and invoke contracts
- Stellar auth, storage, cross-contract calls and custom types
- Stellar Asset Contract and standard token functionality
- Decoding Stellar XDR and parsing transaction responses

You should be able to explain the above concepts and help participants with debugging

### Complete the Following

- [ ] Run through all 3 quests successfully
- [ ] Practice talking points on walking learners through the quests
- [ ] Ensure every participant has:
  - An active Github account
  - Active Discord account connected to [Stellar Dev Discord](https://discord.gg/stellardev) with attached Stellar testnet account

## During the Event

### Gameplay for Quest 1

> [!NOTE]
> Quest 1 vs Quest 2-6 have DIFFERENT Gameplay Loops

Have everyone navigate to the game repository: <https://github.com/anataliocs/soroban-quest>

- Click on the "Open in Codespaces" link -> Click "Continue"
- Have some content to go over during the loading process to keep the audience engaged (5-10min)
- After everything loads -> Click "How-to-play" at the top of the README
  - Introduce the various tools:
    - Quest log
    - Journal
    - VNC embedded Firefox browser
  - Walk through steps to setup the quest
- Next, Click "The First Quest" at the top of the README
  - Open the relevant `lib.rs` contract and explain each line of functionality to the audience
  - Walk through the steps to build the contract and explain what happens during the build process
  - Open the relevant `test.rs` and explain each line of the test
  - Walk through the steps to run the test suite
- Next, have everyone navigate to the smart contract tutorial in the developer documentation: <https://developers.stellar.org/docs/build/smart-contracts/getting-started/deploy-to-testnet>

  ![getting started tutorial](qrcode_developers.stellar.org.png)

- Walk through each step of the deploy tutorial explaining the details of how the Stellar CLI is being used
- Explain how to deploy a contract using the Stellar CLI
- Explain how to invoke a deployed contract using the Stellar CLI
- Navigate back to the README in the Cloud VS Code IDE
  - Deploy the contract you built
  - Invoke the contract you built and be sure to pass in the parameter `--send` set to `yes`
    - e.g. `stellar contract invoke --send=yes`
- Next, Click "Check your Answer" at the top of the README
  - Check your answer using sq check passing in the quest number e.g. `sq check 1`
  - Walk through the process to sign the XDR
  - Walk through the submission process to submit the "Signed XDR" using `sq submit –xdr`

### Gameplay for Quests 2-6

> [!TIP]
> Here is your chance to shine!  You can teach the content listed here for each quest in whatever way you choose.  Slides, live demo, etc.

For help here, attend a DevRel Ambassador briefing session or watch a video of a previous session!
