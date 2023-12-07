
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract HorseRacing {
    address public owner;
    uint256 public raceIdCounter;
    uint256 public maxTicketsPerWallet = 30;
    uint256 public maxTotalTicketsPerRace = 100;
    uint256 public ticketCost = 0.0123 ether;


    event HorseEntered(uint256 indexed raceId, address indexed horse, uint256 quantity);

    struct Race {
        uint256 pid; // Process ID
        string description;
        string specialGuestName;
        mapping(address => uint256) ticketsPerHorse;
        address[] enteredHorses;
        address[] winners;
        bool isOpen;
    }

    mapping(uint256 => Race) public races;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        raceIdCounter = 1; // Start raceId from 1
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

        // Emit an event for the entered horse
        emit HorseEntered(_raceId, msg.sender, _quantity);
    }


    function setTicketCost(uint256 _newCost) external onlyOwner {
        ticketCost = _newCost;
    }

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

    function declareWinners(uint256 _raceId, address[] memory _winners) external onlyOwner {
        require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
        require(_winners.length <= 5, "Exceeded maximum winners");

        races[_raceId].winners = _winners;
    }


    function getTicketsSold(uint256 _raceId) external view returns (uint256) {
       require(_raceId > 0 && _raceId <= raceIdCounter, "Invalid race ID");
       return totalTicketsInRace(_raceId);
    }

    function totalTicketsInRace(uint256 _raceId) internal view returns (uint256) {
       uint256 totalTickets = 0;
       address[] memory horses = races[_raceId].enteredHorses;

        for (uint256 i = 0; i < horses.length; i++) {
           totalTickets += races[_raceId].ticketsPerHorse[horses[i]];
        }

        return totalTickets;
    } function getOpenRaces() external view returns (uint256[] memory) {
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

    function withdrawFunds() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

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
