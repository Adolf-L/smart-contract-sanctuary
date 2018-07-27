pragma solidity ^0.4.24;

/**
 * @dev winner events
 */
contract WinnerEvents {

    event onBuy
    (
        address paddr,
        bytes32 pname,
        uint256 ethIn,
        uint256 timeStamp
    );

    event onBuyName
    (
        address paddr,
        bytes32 pname,
        uint256 ethIn,
        uint256 timeStamp
    );

    event onWithdraw
    (
        address paddr,
        bytes32 pname,
        uint256 ethOut,
        uint256 timeStamp
    );

    event onUpPlayer
    (
        address addr,
        bytes32 pname,
        uint256 balance,
        uint256 interest,
        uint256 win,
        uint256 reff
    );

    event onUpPlayerRound
    (
        address addr,
        uint256 roundID,
        uint256 eth,
        uint256 keys,
        uint256 interest,
        uint256 win,
        uint256 reff
    );


    event onUpRound
    (
        uint256 roundID,
        address leader,
        uint256 start,
        uint256 end,
        bool ended,
        uint256 keys,
        uint256 eth,
        uint256 pool,
        uint256 interest,
        uint256 win,
        uint256 reff
    );


}

/*
 *  @dev winner contract
 */
contract Winner is WinnerEvents {
    using SafeMath for *;
    using NameFilter for string;

//==============================================================================
// game settings
//==============================================================================

    string constant public name = &quot;Im Winner Game&quot;;
    string constant public symbol = &quot;IMW&quot;;


//==============================================================================
// private state variables
//==============================================================================

    // admin address
    address[] private adminAddresses_;

//==============================================================================
// public state variables
//==============================================================================

    // activated flag
    bool public activated_ = false;

    // round id
    uint256 public roundID_;

    // *************
    // player data
    // *************

    uint256 private pIDCount_;

    // return pid by address
    mapping(address => uint256) public address2PID_;

    // return player data by pid (pid => player)
    mapping(uint256 => WinnerDatasets.Player) public pID2Player_;

    // return player round data (pid => rid => player round data)
    mapping(uint256 => mapping(uint256 => WinnerDatasets.PlayerRound)) public pID2Round_;

    // *************
    // round data
    // *************

    // return the round data by rid (rid => round)
    mapping(uint256 => WinnerDatasets.Round) public rID2Round_;


    constructor()
        public
    {
        pIDCount_ = 0;

        adminAddresses_ = new address[](0);
        adminAddresses_.push(0xD272510D0fBFa2918fE91EaA7f6a1f8B08a96069);
    }


//==============================================================================
// function modifiers
//==============================================================================


    /*
     * @dev check if the contract is activated
     */
     modifier isActivated() {
        require(activated_ == true, &quot;the contract is not ready yet&quot;);
        _;
     }

     /**
     * @dev check if the msg sender is human account
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, &quot;sorry humans only&quot;);
        _;
    }

     /*
      * @dev check if admin or not 
      */
    modifier isAdmin() {
        address _addr = msg.sender;
        bool _isAdmin = false;
        for (uint32 i = 0; i < adminAddresses_.length; i++ ) {
            if( _addr == adminAddresses_[i]) {
                _isAdmin = true;
                break;
            }
        }

        require(_isAdmin == true, &quot;sorry admins only&quot;);
        _;
    }

    /**
     * @dev sets boundaries for incoming tx 
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 10000000000, &quot;eth too small&quot;);
        require(_eth <= 100000000000000000000000, &quot;eth too huge&quot;);
        _;    
    }

//==============================================================================
// public functions
//==============================================================================

    /*
     *  @dev send eth to contract
     */
    function ()
    public
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    payable {
        buyCore(msg.sender, msg.value);
    }

    /*
     *  @dev send eth to contract
     */
    function buyKey()
    public
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    payable {
        buyCore(msg.sender, msg.value);
    }


    /*
     *  @dev buy name
     */
    function buyName(string pname)
    public
    isActivated()
    isHuman()
    isWithinLimits(msg.value)
    payable {

        uint256 pID = address2PID_[msg.sender];

        // new player
        if( pID == 0 ) {
            pIDCount_++;

            pID = pIDCount_;
            WinnerDatasets.Player memory player = WinnerDatasets.Player(pID, msg.sender, 0, 0, 0, 0, 0);
            WinnerDatasets.PlayerRound memory playerRound = WinnerDatasets.PlayerRound(0, 0, 0, 0, 0);

            pID2Player_[pID] = player;
            pID2Round_[pID][roundID_] = playerRound;

            address2PID_[msg.sender] = pID;
        }

        pID2Player_[pID].pname = pname.nameFilter();

        // fire buy  event 
        emit WinnerEvents.onBuyName
        (
            msg.sender, 
            pID2Player_[pID].pname, 
            msg.value, 
            now
        );
        
    }

//==============================================================================
// private functions
//==============================================================================    

    function isAdminAddressExist(address addr)
    private
    view
    returns (bool) {

        for(uint256 i = 0; i<adminAddresses_.length; i++) {
            if( adminAddresses_[i] == addr ) {
                return (true);
            }
        }
        return (false);
    }

    function getAdminAddressIndex(address addr) 
    private
    view
    returns (uint256) {
        for(uint256 i = 0; i<adminAddresses_.length; i++) {
            if( adminAddresses_[i] == addr ) {
                return (i);
            }
        }
        return (0);
    }

    function buyCore(address addr, uint256 eth) 
    private {
        uint256 pID = address2PID_[addr];

        // new player
        if( pID == 0 ) {
            pIDCount_++;

            pID = pIDCount_;
            WinnerDatasets.Player memory player = WinnerDatasets.Player(pID, addr, 0, 0, 0, 0, 0);
            WinnerDatasets.PlayerRound memory playerRound = WinnerDatasets.PlayerRound(0, 0, 0, 0, 0);

            pID2Player_[pID] = player;
            pID2Round_[pID][roundID_] = playerRound;

            address2PID_[addr] = pID;
        }

        // fire buy  event 
        emit WinnerEvents.onBuy
        (
            addr, 
            pID2Player_[pID].pname, 
            eth, 
            now
        );
    }

    
//==============================================================================
// admin functions
//==============================================================================    

    /*
     * @dev activate the contract
     */
    function activate() 
    isAdmin()
    public 
     {
        require( activated_ == false, &quot;contract is activated&quot;);

        activated_ = true;

        // start the first round
        roundID_ = 1;
    }

    /*
     *  @dev user withdraw
     */
    function withdraw(address addr, uint256 eth)
    public 
    isActivated() 
    isAdmin() 
    isWithinLimits(eth) {

        uint pID = address2PID_[addr];
        require(pID > 0, &quot;user not exist&quot;);

        addr.transfer(eth);

        // fire the withdraw event
        emit WinnerEvents.onWithdraw
        (
            msg.sender, 
            pID2Player_[pID].pname, 
            eth, 
            now
        );
    }

    /*
     *  @dev add admin address
     */
    function addAdminAddress(address addr) 
    isAdmin()
    public {
        bool isExist = isAdminAddressExist(addr);

        require( isExist == false, &quot;addmin address exist&quot;);

        adminAddresses_.push(addr);
    }

    /*
     *  @dev remove admin address
     */
    function removeAdminAddress(address addr) 
    isAdmin()
    public {
        bool isExist = isAdminAddressExist(addr);

        require( isExist == true, &quot;admin address not exist&quot;);

        require( addr != msg.sender, &quot;admin cannot remove self&quot;);

        uint256 idx = getAdminAddressIndex(addr);
        for( uint256 i = idx; i<adminAddresses_.length-1; i++) {
            adminAddresses_[i] = adminAddresses_[i+1];
        }

        delete adminAddresses_[adminAddresses_.length-1];
        adminAddresses_.length--;
    }

    /*
     *  @dev get admin addresses
     */

    function getAdminAddresses() 
    isAdmin()
    public
    view
    returns (address[]) {
        return (adminAddresses_);
    }

    /*
     * @dev upPlayer
     */
    function upPlayer(address addr, bytes32 pname, uint256 balance, uint256 interest, uint256 win, uint256 reff)
    isAdmin()
    isActivated()
    public {

        uint256 pID = address2PID_[addr];

        require( pID != 0, &quot;cannot find the player&quot;);
        require( balance >= 0, &quot;balance invalid&quot;);
        require( interest >= 0, &quot;interest invalid&quot;);
        require( win >= 0, &quot;win invalid&quot;);
        require( reff >= 0, &quot;reff invalid&quot;);

        pID2Player_[pID].pname = pname;
        pID2Player_[pID].balance = balance;
        pID2Player_[pID].interest = interest;
        pID2Player_[pID].win = win;
        pID2Player_[pID].reff = reff;

        // fire the event
        emit WinnerEvents.onUpPlayer
        (
            addr,
            pname,
            balance,
            interest,
            win,
            reff
        );
    }


    function upPlayerRound(address addr, uint256 roundID, uint256 eth, uint256 keys, uint256 interest, uint256 win, uint256 reff)
    isAdmin()
    isActivated() 
    public {
        uint256 pID = address2PID_[addr];

        require( pID != 0, &quot;cannot find the player&quot;);
        require( roundID == roundID_, &quot;not current round&quot;);
        require( eth >= 0, &quot;eth invalid&quot;);
        require( keys >= 0, &quot;keys invalid&quot;);
        require( interest >= 0, &quot;interest invalid&quot;);
        require( win >= 0, &quot;win invalid&quot;);
        require( reff >= 0, &quot;reff invalid&quot;);

        pID2Round_[pID][roundID_].eth = eth;
        pID2Round_[pID][roundID_].keys = keys;
        pID2Round_[pID][roundID_].interest = interest;
        pID2Round_[pID][roundID_].win = win;
        pID2Round_[pID][roundID_].reff = reff;

        // fire the event
        emit WinnerEvents.onUpPlayerRound
        (
            addr,
            roundID,
            eth,
            keys,
            interest,
            win,
            reff
        );
    }


    /*
     * @dev upRound
     */
    function upRound(uint256 roundID, address leader, uint256 start, uint256 end, bool ended, uint256 keys, uint256 eth, uint256 pool, uint256 interest, uint256 win, uint256 reff)
    isAdmin()
    isActivated()
    public {

        require( roundID == roundID_, &quot;not current round&quot;);

        uint256 pID = address2PID_[leader];
        require( pID != 0, &quot;cannot find the leader&quot;);
        require( end >= start, &quot;start end invalid&quot;);
        require( keys >= 0, &quot;keys invalid&quot;);
        require( eth >= 0, &quot;eth invalid&quot;);
        require( pool >= 0, &quot;pool invalid&quot;);
        require( interest >= 0, &quot;interest invalid&quot;);
        require( win >= 0, &quot;win invalid&quot;);
        require( reff >= 0, &quot;reff invalid&quot;);

        rID2Round_[roundID_].leader = leader;
        rID2Round_[roundID_].start = start;
        rID2Round_[roundID_].end = end;
        rID2Round_[roundID_].ended = ended;
        rID2Round_[roundID_].keys = keys;
        rID2Round_[roundID_].eth = eth;
        rID2Round_[roundID_].pool = pool;
        rID2Round_[roundID_].interest = interest;
        rID2Round_[roundID_].win = win;
        rID2Round_[roundID_].reff = reff;

        // fire the event
        emit WinnerEvents.onUpRound
        (
            roundID,
            leader,
            start,
            end,
            ended,
            keys,
            eth,
            pool,
            interest,
            win,
            reff
        );
    }
}


//==============================================================================
// interfaces
//==============================================================================


//==============================================================================
// structs
//==============================================================================

library WinnerDatasets {

    struct Player {
        uint256 pId;        // player id
        address addr;       // player address
        bytes32 pname;      // player name
        uint256 balance;    // eth balance
        uint256 interest;   // interest total
        uint256 win;        // win total
        uint256 reff;       // reff total
    }

    struct PlayerRound {
        uint256 eth;        // eth player has added to round (used for eth limiter)
        uint256 keys;       // keys
        uint256 interest;   // interest total
        uint256 win;        // win total
        uint256 reff;       // reff total
    }

    struct Round {
        address leader;     // pID of player in lead
        uint256 start;      // time start
        uint256 end;        // time ends/ended
        bool ended;         // has round end function been ran
        uint256 keys;       // keys
        uint256 eth;        // total eth in
        uint256 pool;       // pool eth
        uint256 interest;   // interest total
        uint256 win;        // win total
        uint256 reff;       // reff total
    }
}

//==============================================================================
// libraries
//==============================================================================

library NameFilter {

    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, &quot;string must be between 1 and 32 characters&quot;);
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, &quot;string cannot start or end with space&quot;);
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, &quot;string cannot start with 0x&quot;);
            require(_temp[1] != 0x58, &quot;string cannot start with 0X&quot;);
        }
        
        // create a bool to track if we have a non number character
        bool _hasNonNumber;
        
        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
               require
                (
                    // require character is a space
                    _temp[i] == 0x20 || 
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    &quot;string contains invalid characters&quot;
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, &quot;string cannot contain consecutive spaces&quot;);
                
                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, &quot;string cannot be only numbers&quot;);
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}


/*
 * @dev safe math
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, &quot;SafeMath mul failed&quot;);
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, &quot;SafeMath sub failed&quot;);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, &quot;SafeMath add failed&quot;);
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}