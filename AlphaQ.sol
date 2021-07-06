pragma solidity ^0.5.11;


contract AlphaQ{
    
    address public owner;
    
    uint256 private initDeposit; // value in ethers
    uint256 public clientCount;
    uint256 public tenderCode; // gives the number of tendors and the last tender code allocated
    uint256 public bidCode; // gives the number of bids submitted and the last bid submitted
    
    
    string constant private ONLY_OWNER_ACCESS="1";
    string constant private DUPLICATE_USERNAME="2";
    string constant private USER_DOESNT_EXIST="3";
    string constant private INSUFFICIENT_FUNDS="4";
    string constant private NOT_TENDER_CREATOR="5";
    string constant private WRONG_SECRET_KEY="6";
    string constant private TENDER_DOESNT_EXIST="7";
    string constant private INAPPROPRIATE_DEADLINES="8";
    string constant private DEADLINE1_PASSED="9";
    string constant private DEADLINE2_PASSED="10";
    string constant private DEADLINE1_HASNT_PASSED="11";
    string constant private DEADLINE2_HASNT_PASSED="12";
    string constant private TENDER_CLOSED="13";
    string constant private FAKE_IDENTITY="14";
    string constant private BID_DOESNT_EXIST="15";
    
    
    struct userInfo{
        string passHash;
        string encKey;
        address puk;
        bool isSet;
        bool isTenderCreator;
        uint256[] tendersSubmitted;
    }
    
    struct tenderInfo{
        string creatorUsername;
        string tenderDetailURL;
        string tenderDetailHash;
        uint256 deadline1;
        uint256 deadline2;
        uint256[] bidsSubmitted;
        bool winnerDeclared;
        uint256 winnerBidCode;
        bool tenderClosed;
        bool isSet;
    }
    
    struct bidInfo{
        string creatorUsername;
        uint256 tenderCode;
        string encBidURL;
        string encBidHash;
        string encBidKey;
        bool isSet;
        bool encKeyExists;
    }
    
    
    mapping(string=>userInfo) public userData;
    mapping(uint256=>tenderInfo) public tenderData;
    mapping(uint256=>bidInfo) public bidData;
    
    
    constructor() public{
        owner = msg.sender;
        clientCount = 0;
        initDeposit = 0;
        tenderCode = 0;
        bidCode = 0;
    }
    
    modifier onlyowner() {
        require(msg.sender==owner, ONLY_OWNER_ACCESS);
        _;
    }
    
        
    // function concat(bytes memory a, bytes memory b) internal pure returns (bytes memory) {
    //     return abi.encodePacked(a, b);
    // }
    
    function createAccount(string memory _username, string memory _passHash, string memory _encKey) public payable returns(bool) {
        require(userData[_username].isSet == false, DUPLICATE_USERNAME);
        require(msg.value >= initDeposit, INSUFFICIENT_FUNDS);
        userData[_username] = userInfo(_passHash, _encKey, msg.sender, true, false, new uint256[](0));
        clientCount++;
        return true;
    }
    
    function usernameExists(string memory _username) public view returns(bool) {
        return userData[_username].isSet;
    } 
    
    function fetchpassHash(string memory _username) public view returns(string memory) { // wallet app will call this
        return userData[_username].passHash;
    }
    function fetchencKey(string memory _username) public view returns(string memory) { // wallet app will call this
        return userData[_username].encKey;
    }
    
    function changePassword(string memory _username, string memory _newpassHash, string memory _newencKey) public {
        require(userData[_username].isSet == true, USER_DOESNT_EXIST);
        require(userData[_username].puk == msg.sender, WRONG_SECRET_KEY);
        userData[_username].passHash = _newpassHash;
        userData[_username].encKey = _newencKey;
    }
    
    
    function setTenderCreator(string memory _username) public onlyowner{
        require(userData[_username].isSet == true, USER_DOESNT_EXIST);
        userData[_username].isTenderCreator=true;
    }
    
    function createTender(string memory _username, string memory _tenderDetailHash, string memory _tenderDetailURL, uint256 _mindeadline1 , uint256 _mindeadline2) public{
        require(userData[_username].isSet==true, USER_DOESNT_EXIST);
        require(userData[_username].puk == msg.sender, FAKE_IDENTITY);
        require(userData[_username].isTenderCreator == true, NOT_TENDER_CREATOR);
        require(_mindeadline1 < _mindeadline2, INAPPROPRIATE_DEADLINES);
        tenderCode++;
        tenderData[tenderCode].creatorUsername = _username;
        userData[_username].tendersSubmitted.push(tenderCode);
        tenderData[tenderCode].tenderDetailURL = _tenderDetailURL;
        tenderData[tenderCode].tenderDetailHash = _tenderDetailHash;
        tenderData[tenderCode].deadline1 = now + (_mindeadline1 * (1 minutes));
        tenderData[tenderCode].deadline2 = now + (_mindeadline2 * (1 minutes));
        tenderData[tenderCode].winnerDeclared = false;
        tenderData[tenderCode].tenderClosed = false;
        tenderData[tenderCode].isSet = true;
    }
    
    function submitEncBid(string memory _username, uint256 _tenderCode, string memory _encBidHash, string memory _encBidURL) public{
        require(userData[_username].isSet == true, USER_DOESNT_EXIST);
        require(userData[_username].puk == msg.sender, FAKE_IDENTITY); 
        require(tenderData[_tenderCode].isSet==true, TENDER_DOESNT_EXIST);
        require(now < tenderData[_tenderCode].deadline1, DEADLINE1_PASSED);
        require(tenderData[_tenderCode].tenderClosed == false, TENDER_CLOSED);
        
        bidCode++;
        bidData[bidCode].creatorUsername = _username;
        tenderData[_tenderCode].bidsSubmitted.push(bidCode);
        bidData[bidCode].tenderCode = _tenderCode;
        bidData[bidCode].encBidURL = _encBidURL;
        bidData[bidCode].encBidHash = _encBidHash;
        bidData[bidCode].isSet = true;
        bidData[bidCode].encKeyExists = false;
    }
    
    function getContractOwnerKey(uint256 _tenderCode) public view returns(address){
        return userData[tenderData[_tenderCode].creatorUsername].puk;
    }
    
    function submitBidKey(string memory _username, uint256 _bidCode, string memory _encBidKey) public{
        require(userData[_username].isSet == true, USER_DOESNT_EXIST);
        require(userData[_username].puk == msg.sender, FAKE_IDENTITY);
        require(bidData[_bidCode].isSet==true, BID_DOESNT_EXIST);
        require(userData[bidData[_bidCode].creatorUsername].puk == msg.sender, ONLY_OWNER_ACCESS);
        require(now < tenderData[bidData[_bidCode].tenderCode].deadline2, DEADLINE2_PASSED);
        require(now > tenderData[bidData[_bidCode].tenderCode].deadline1, DEADLINE1_HASNT_PASSED);
        require(tenderData[bidData[_bidCode].tenderCode].tenderClosed == false, TENDER_CLOSED);
        bidData[_bidCode].encBidKey = _encBidKey;
        bidData[_bidCode].encKeyExists = true;
    }
    
    function declareWinner(string memory _username, uint256 _winnerBidCode, uint256 _tenderCode) public{
        require(userData[_username].isSet == true, USER_DOESNT_EXIST);
        require(userData[_username].puk == msg.sender, FAKE_IDENTITY);
        require(tenderData[_tenderCode].isSet==true, TENDER_DOESNT_EXIST);
        require(userData[tenderData[_tenderCode].creatorUsername].puk == msg.sender, ONLY_OWNER_ACCESS);
        require(bidData[_winnerBidCode].isSet==true, BID_DOESNT_EXIST);
        require(now >= tenderData[_tenderCode].deadline2, DEADLINE2_HASNT_PASSED);
        require(tenderData[_tenderCode].tenderClosed == false, TENDER_CLOSED);
        tenderData[_tenderCode].winnerDeclared = true;
        tenderData[_tenderCode].winnerBidCode = _winnerBidCode;
    }
    
    
    function closeTender(string memory _username, uint256 _tenderCode) public{
        require(userData[_username].isSet == true, USER_DOESNT_EXIST);
        require(userData[_username].puk == msg.sender, FAKE_IDENTITY);
        require(tenderData[_tenderCode].isSet==true, TENDER_DOESNT_EXIST);
        require(userData[tenderData[_tenderCode].creatorUsername].puk == msg.sender, ONLY_OWNER_ACCESS);
        tenderData[_tenderCode].tenderClosed=true;
    }
}