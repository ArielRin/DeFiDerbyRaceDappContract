# DeFi Derby Raceing Dapps Smart Contract


## Launch Alpha

https://scan.maxxchain.org/address/0x736fcd8557bd5d2F9bb8b623BE26296C82f02910/

https://bscscan.com/address/0x60a29Aea93b0d1F3849D0Aeb2376B4c612F942ab/

## Dapp Repo
Link to repo with basic user front and with profile creation and points system for leaderboard bragging rights
Simple to use frontend with open races easily accessable to public.


### Frontend

Simple frontend to enter open race events

- Current races will be displayed in cards
- locate the race to enter
- Select qty ticket in races
- Enter the race buy clicking "Enter Race" button
- Confirm TX
- Await Results


TODO

Link contract statistics to leaderboard page


### backend

Extensive backend for administration contract function in an easy admin gui

Admin Page features

- Create a race
- Open / Close a Race Event
- List entries in string to parse to game
- Declare winners
- Set ticket costs
- Set treasury
- withdraw race funds to distribute
- send to payment splitter






This Solidity smart contract, named `DeFiDerbyBNB`, allows users to participate in horse races by entering with a specified quantity of tickets. The contract is designed to be managed by an owner who has control over creating races, opening and closing them, setting ticket costs, and declaring winners.

## How to Interact with the Smart Contract

### 1. Entering a Race

To enter a race, participants can follow these steps:

- **Step 1:** Call the `enterRace` function, specifying the race ID and the quantity of tickets to purchase.

  ```solidity
  function enterRace(uint256 _raceId, uint256 _quantity) external payable;
  ```

  - Ensure that the amount of Ether sent with the transaction matches the cost of the tickets.
  - Verify that the race is open and has available slots.
  - Check if the participant is not exceeding the maximum tickets per wallet or the maximum total tickets for the race.

  **Example:**
  ```solidity
  // Entering Race ID 1 with 3 tickets
  HorseRacing.enterRace{value: 0.0369 ether}(1, 3);
  ```

### 2. Creating a Race

Only the owner of the smart contract can create a race.

- **Step 1:** Call the `createRace` function with the race description and the name of a special guest.

  ```solidity
  function createRace(string calldata _description, string calldata _specialGuestName) external onlyOwner;
  ```

  **Example:**
  ```solidity
  // Creating a new race
  HorseRacing.createRace("Summer Derby", "John Doe");
  ```

### 3. Opening and Closing a Race

The owner can control the state of a race by opening or closing it.

- **Opening a Race:**
  ```solidity
  function openRace(uint256 _raceId) external onlyOwner;
  ```

- **Closing a Race:**
  ```solidity
  function closeRace(uint256 _raceId) external onlyOwner;
  ```

  **Example:**
  ```solidity
  // Opening Race ID 1
  HorseRacing.openRace(1);

  // Closing Race ID 2
  HorseRacing.closeRace(2);
  ```

### 4. Declaring Winners

The owner can declare the winners of a race.

- **Declaring Winners:**
  ```solidity
  function declareWinners(uint256 _raceId, address[] memory _winners) external onlyOwner;
  ```

  - Provide an array of winner addresses (up to 5 winners).

  **Example:**
  ```solidity
  // Declaring winners for Race ID 3
  address[] memory winners = [0x123..., 0x456...];
  HorseRacing.declareWinners(3, winners);
  ```

### Additional Functions

- **Setting Ticket Cost:**
  ```solidity
  function setTicketCost(uint256 _newCost) external onlyOwner;
  ```

- **Withdrawing Funds:**
  ```solidity
  function withdrawFunds() external onlyOwner;
  ```

- **Recovering Lost Tokens (ETH or ERC-20):**
  ```solidity
  function recoverLostTokens(address _tokenAddress, uint256 _amount) external onlyOwner;
  ```

  - Specify the token address (use `address(0)` for Ether) and the amount to recover.

## Important Notes

- Ensure that you are using a compatible Ethereum wallet (e.g., MetaMask) to interact with the smart contract.
- Double-check the gas fees and provide enough Ether for the transaction.
- Review the race details, such as maximum tickets per wallet and per race, before entering.

Feel free to adapt the examples to your specific use case, and always test transactions on a testnet before deploying on the mainnet.
