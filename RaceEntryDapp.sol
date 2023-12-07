// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC-20 Interface for token transfers
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

// Main HorseRacing contract
contract HorseRacing {
    // Address of the contract owner
    address public owner;

    // Counter for unique race IDs
    uint256 public raceIdCounter;

    // Maximum number of tickets an individual wallet can purchase for a race
    uint256 public maxTicketsPerWallet = 30;

    // Maximum total number of tickets allowed for a single race
    uint256 public maxTotalTicketsPerRace = 100;

    // Cost of a single ticket in ether
    uint256 public ticketCost = 0.0123 ether;

    // Event emitted when a horse is entered into a race
    event HorseEntered(uint256 indexed raceId, address indexed horse, uint256 quantity);

    // Struct representing a horse racing event
    struct Race {
        uint256 pid; // Process ID
        string description;
        string specialGuestName;
        mapping(address => uint256) ticketsPerHorse;
        address[] enteredHorses;
        address[] winners;
        bool isOpen;
    }

    // Mapping of race ID to Race struct
    mapping(uint256 => Race) public races;

    // Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Contract constructor
    constructor() {
        owner = msg.sender;
        raceIdCounter = 1; // Start raceId from 1
    }

    // Function to create a new race
    function createRace(string calldata _description, string calldata _specialGuestName) external onlyOwner {
        uint256 newRaceId = raceIdCounter;
        races[newRaceId].pid = newRaceId;
        races[newRaceId].description = _description;
        races[newRaceId].specialGuestName = _specialGuestName;
        races[newRaceId].isOpen = true;
        raceIdCounter++;
    }

    // Function to enter a race by purchasing tickets
    function enterRace(uint256 _raceId, uint256 _quantity) external payable {
        require(msg.value == ticketCost * _quantity, "Incorrect amount sent");
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        require(races[_raceId].isOpen, "Race is closed");
        require(races[_raceId].ticketsPerHorse[msg.sender] + _quantity <= maxTicketsPerWallet, "Exceeded max tickets per wallet");
        require(totalTicketsInRace(_raceId) + _quantity <= maxTotalTicketsPerRace, "Exceeded max total tickets in race");

        races[_raceId].enteredHorses.push(msg.sender);
        races[_raceId].ticketsPerHorse[msg.sender] += _quantity;

        // Emit an event for the entered horse
        emit HorseEntered(_raceId, msg.sender, _quantity);
    }

    // Function to set the cost of a ticket
    function setTicketCost(uint256 _newCost) external onlyOwner {
        ticketCost = _newCost;
    }

    // Function to get the list of entered horses in a race
    function getEnteredHorses(uint256 _raceId) external view returns (address[] memory) {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");

        // Create a dynamic array to store entered horses
        address[] memory enteredHorses;

        // Iterate through the events to find entered horses for the given race
        for (uint256 i = 0; i < races[_raceId].enteredHorses.length; i++) {
            address horse = races[_raceId].enteredHorses[i];
            uint256 quantity = races[_raceId].ticketsPerHorse[horse];

            // Repeat the horse address based on the quantity
            for (uint256 j = 0; j < quantity; j++) {
                enteredHorses = appendToAddressArray(enteredHorses, horse);
            }
        }

        return enteredHorses;
    }

    // Helper function to append an address to an array
    function appendToAddressArray(address[] memory array, address element) internal pure returns (address[] memory) {
        address[] memory newArray = new address[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = element;
        return newArray;
    }

    // Function to get the quantity of tickets entered by a horse in a race
    function getQtyTicketsEnteredInRace(uint256 _raceId, address _horse) external view returns (uint256) {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        return races[_raceId].ticketsPerHorse[_horse];
    }

    // Function to get the winners' addresses as a string
    function getWinnersString(uint256 _raceId) external view returns (string memory) {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");

        address[] memory winners = races[_raceId].winners;
        string memory winnersString;

        for (uint256 i = 0; i < winners.length; i++) {
            winnersString = string(abi.encodePacked(winnersString, ",", addressToString(winners[i])));
        }

        return winnersString;
    }

    // Function to open a closed race
    function openRace(uint256 _raceId) external onlyOwner {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        require(!races[_raceId].isOpen, "Race is already open");

        races[_raceId].isOpen = true;
    }

    // Function to close an open race
    function closeRace(uint256 _raceId) external onlyOwner {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        require(races[_raceId].isOpen, "Race is already closed");

        races[_raceId].isOpen = false;
    }

    // Function to close all open races
    function closeAllRaces() external onlyOwner {
        for (uint256 i = 1; i <= raceIdCounter; i++) {
            if (races[i].isOpen) {
                races[i].isOpen = false;
            }
        }
    }

    // Function to declare winners for a race
    function declareWinners(uint256 _raceId, address[] memory _winners) external onlyOwner {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        require(_winners.length <= 5, "Exceeded maximum winners");

        races[_raceId].winners = _winners;
    }

    // Function to get the total number of tickets sold for a race
    function getTicketsSold(uint256 _raceId) external view returns (uint256) {
       require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
       return totalTicketsInRace(_raceId);
    }

    // Internal function to calculate the total number of tickets sold for a race
    function totalTicketsInRace(uint256 _raceId) internal view returns (uint256) {
       uint256 totalTickets = 0;
       address[] memory horses = races[_raceId].enteredHorses;

        for (uint256 i = 0; i < horses.length; i++) {
           totalTickets += races[_raceId].ticketsPerHorse[horses[i]];
        }

        return totalTickets;
    }

    // Function to get the list of open races
    function getOpenRaces() external view returns (uint256[] memory) {
        uint256[] memory openRaceIds;
        uint256 count = 0;

        for (uint256 i = 1; i <= raceIdCounter; i++) {
            if (races[i].isOpen) {
                // Include open race ID in the list
                openRaceIds[count] = i;
                count++;
            }
        }

        // Create a new array with the correct length to show open races
        uint256[] memory result = new uint256[](count);
        for (uint256 j = 0; j < count; j++) {
            result[j] = openRaceIds[j];
        }

        return result;
    }

    // Function to convert an address to a string
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

    // Function to withdraw funds from the contract
    function withdrawFunds() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Function to recover lost ERC-20 tokens or native Ether
    function recoverLostTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        if (_tokenAddress == address(0)) {
            // Recover native Ether
            payable(owner).transfer(_amount);
        } else {
            // Recover ERC-20 tokens
            IERC20(_tokenAddress).transfer(owner, _amount);
        }
    }
}
