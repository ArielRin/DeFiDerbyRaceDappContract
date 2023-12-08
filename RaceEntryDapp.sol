// SPDX-License-Identifier: MIT

//teamprize pool wallet 0x6b5CCBBD51493e2689223dBC9580243d7abAC05e

pragma solidity ^0.8.0;

// ERC-20 Interface for token transfers
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

// Main DefiDerbyHorseRaces contract
contract DefiDerbyHorseRaces {
    address public owner;
    address public treasuryWallet;  // Treasury wallet address
    uint256 public raceIdCounter;
    uint256 public maxTicketsPerWallet = 30;
    uint256 public maxTotalTicketsPerRace = 99;
    uint256 public ticketCost = 0.0123 ether;

    event HorseEntered(uint256 indexed raceId, address indexed horse, uint256 quantity);
    event WinnersDeclared(uint256 indexed raceId, address[] winners, uint256[] percentages);

    struct Race {
        uint256 pid;
        string description;
        string specialGuestName;
        mapping(address => uint256) ticketsPerHorse;
        address[] enteredHorses;
        address[] winners;
        bool isOpen;
    }

    mapping(uint256 => Race) public races;
    mapping(uint256 => bool) public raceWithdrawn;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyOwnerOrTreasury() {
        require(msg.sender == owner || msg.sender == treasuryWallet, "Not authorized");
        _;
    }

    constructor(address _treasuryWallet) {
        owner = msg.sender;
        treasuryWallet = _treasuryWallet;
        raceIdCounter = 1;
    }

    function setTreasuryWallet(address _newTreasuryWallet) external onlyOwner {
        treasuryWallet = _newTreasuryWallet;
    }

    function createRace(string calldata _description, string calldata _specialGuestName) external onlyOwner {
        uint256 newRaceId = raceIdCounter;
        races[newRaceId].pid = newRaceId;
        races[newRaceId].description = _description;
        races[newRaceId].specialGuestName = _specialGuestName;
        races[newRaceId].isOpen = true;
        raceIdCounter++;
    }

    function enterRace(uint256 _raceId, uint256 _quantity) external payable {
        require(msg.value == ticketCost * _quantity, "Incorrect amount sent");
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        require(races[_raceId].isOpen, "Race is closed");
        require(races[_raceId].ticketsPerHorse[msg.sender] + _quantity <= maxTicketsPerWallet, "Exceeded max tickets per wallet");
        require(totalTicketsInRace(_raceId) + _quantity <= maxTotalTicketsPerRace, "Exceeded max total tickets in race");

        races[_raceId].enteredHorses.push(msg.sender);
        races[_raceId].ticketsPerHorse[msg.sender] += _quantity;

        emit HorseEntered(_raceId, msg.sender, _quantity);
    }

    function setTicketCost(uint256 _newCost) external onlyOwner {
        ticketCost = _newCost;
    }

    function declareWinnersAndPay(uint256 _raceId, address[] memory _winners, uint256[] memory _percentageDistribution) external onlyOwner {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        require(_winners.length <= 5, "Exceeded maximum winners");
        require(_winners.length == _percentageDistribution.length, "Mismatch in winners and percentage distribution length");

        races[_raceId].winners = _winners;

        uint256 totalAmount = totalTicketsInRace(_raceId) * ticketCost;

        for (uint256 i = 0; i < _winners.length; i++) {
            address winner = _winners[i];
            uint256 percentage = _percentageDistribution[i];

            require(percentage <= 100, "Invalid percentage");

            uint256 amountToSend = (totalAmount * percentage) / 100;

            payable(winner).transfer(amountToSend);
            totalAmount -= amountToSend;
        }

        payable(treasuryWallet).transfer(totalAmount);

        emit WinnersDeclared(_raceId, _winners, _percentageDistribution);
    }

    function getEnteredHorses(uint256 _raceId) external view returns (address[] memory) {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");

        address[] memory enteredHorses;

        for (uint256 i = 0; i < races[_raceId].enteredHorses.length; i++) {
            address horse = races[_raceId].enteredHorses[i];
            uint256 quantity = races[_raceId].ticketsPerHorse[horse];

            for (uint256 j = 0; j < quantity; j++) {
                enteredHorses = appendToAddressArray(enteredHorses, horse);
            }
        }

        return enteredHorses;
    }

    function getQtyTicketsEnteredInRace(uint256 _raceId, address _horse) external view returns (uint256) {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        return races[_raceId].ticketsPerHorse[_horse];
    }

    function getWinnersString(uint256 _raceId) external view returns (string memory) {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");

        address[] memory winners = races[_raceId].winners;
        string memory winnersString;

        for (uint256 i = 0; i < winners.length; i++) {
            winnersString = string(abi.encodePacked(winnersString, ",", addressToString(winners[i])));
        }

        return winnersString;
    }

    function openRace(uint256 _raceId) external onlyOwner {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        require(!races[_raceId].isOpen, "Race is already open");

        races[_raceId].isOpen = true;
    }

    function closeRace(uint256 _raceId) external onlyOwner {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        require(races[_raceId].isOpen, "Race is already closed");

        races[_raceId].isOpen = false;
    }

    function closeAllRaces() external onlyOwner {
        for (uint256 i = 1; i <= raceIdCounter; i++) {
            if (races[i].isOpen) {
                races[i].isOpen = false;
            }
        }
    }

    function getTicketsSold(uint256 _raceId) external view returns (uint256, uint256) {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        uint256 sold = totalTicketsInRace(_raceId);
        uint256 value = sold * ticketCost;
        return (sold, value);
    }

    function calculateRaceValue(uint256 _raceId) internal view returns (uint256) {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        return totalTicketsInRace(_raceId) * ticketCost;
    }

    function getRaceValue(uint256 _raceId) external view returns (uint256) {
        return calculateRaceValue(_raceId);
    }

    function withdrawFunds(uint256 _raceId) external onlyOwnerOrTreasury {
    require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
    require(!raceWithdrawn[_raceId], "Funds already withdrawn for this race");

    uint256 raceValue = calculateRaceValue(_raceId);

    require(raceValue > 0, "No funds available for the specified race");

    payable(treasuryWallet).transfer(raceValue);

    raceWithdrawn[_raceId] = true;

    // Close the race after withdrawing funds
    races[_raceId].isOpen = false;
}

    function getOpenRaces() external view returns (uint256[] memory) {
        uint256 count = 0;

        for (uint256 i = 1; i <= raceIdCounter; i++) {
            if (races[i].isOpen) {
                count++;
            }
        }

        uint256[] memory openRaceIds = new uint256[](count);
        uint256 index = 0;

        for (uint256 j = 1; j <= raceIdCounter; j++) {
            if (races[j].isOpen) {
                openRaceIds[index] = j;
                index++;
            }
        }

        return openRaceIds;
    }

    function addressToString(address account) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(account)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function recoverLostTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        if (_tokenAddress == address(0)) {
            payable(owner).transfer(_amount);
        } else {
            IERC20(_tokenAddress).transfer(owner, _amount);
        }
    }

    function appendToAddressArray(address[] memory array, address element) internal pure returns (address[] memory) {
        address[] memory newArray = new address[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = element;
        return newArray;
    }

    function totalTicketsInRace(uint256 _raceId) internal view returns (uint256) {
        uint256 totalTickets = 0;
        address[] memory horses = races[_raceId].enteredHorses;

        for (uint256 i = 0; i < horses.length; i++) {
            totalTickets += races[_raceId].ticketsPerHorse[horses[i]];
        }

        return totalTickets;
    }

    function getFullRaceDetails(uint256 _raceId) external view returns (
    uint256 pid,
    string memory description,
    string memory specialGuestName,
    address[] memory enteredHorses,
    address[] memory winners,
    bool isOpen,
    bool winnersDeclared,
    bool fundsWithdrawn,  // New boolean indicating whether funds have been withdrawn
    uint256 totalTicketsSold,
    uint256 totalRaceValue
) {
    require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");

    Race storage race = races[_raceId];

    pid = race.pid;
    description = race.description;
    specialGuestName = race.specialGuestName;
    enteredHorses = race.enteredHorses;
    winners = race.winners;
    isOpen = race.isOpen;
    winnersDeclared = race.winners.length > 0;
    fundsWithdrawn = raceWithdrawn[_raceId];  // Check if funds have been withdrawn
    totalTicketsSold = totalTicketsInRace(_raceId);
    totalRaceValue = calculateRaceValue(_raceId);
}

}
