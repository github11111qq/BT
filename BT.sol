pragma solidity ^0.5.7;


import "./SafeMath57.sol";


contract BT {
using SafeMath for *;
struct affOrder{
    uint256 fromId;
    uint256 getpId;
    uint256 value;
    bool status;
    }
struct champion {
    uint256 roundId;
    uint256 maxUsers;
    uint256 pId;
    address addr;
    uint256 pot;
    string  username;
    uint256 openTime;
    
}

struct BetHistory{
    uint256 pid;
    uint256 datetime;
    uint256 eth;
    uint256 roundId;

}



uint256 ethWei = 1 ether;

 uint256  private minbeteth_ = 1 * ethWei;      
 uint256 constant private getoutBeishu = 21;         
 uint256 public nextId_ = 1;                      
 uint256  genReleTime_ = 24 hours;                  
 bool public activated_ = true;   

 mapping (address => uint256)   public pIDxAddr_;         
 mapping (uint256 => Player)    public plyr_;            
 mapping (string   => uint256) public pIDInviteCode_;
 mapping (uint256   => uint256[]) public curchampionQue_;

    
 uint256 public gBet_ = 0 ;
 uint256 public gWithDraw_ = 0;
 uint256 public gBetcc_ =0;

 uint256 public genRate_ = 1;
 uint256[10] affRate = [200,100,50,20,20,20,20,20,20,20];
 

uint256 public championPot_ = 0;
uint256 public championTime_ = 24 hours;
uint256 public championRound_ = 1;
uint256 public championRate_ = 10;
uint256 public championStartTime_ = 0 ;
uint256 public curchampionMaxUser_ = 0;
 
uint256 public curchampionPid_ = 0;
uint256 public lastChampionPid_ = 0;
uint256 public gOrderId_ =0;


constructor()
public
{

    championStartTime_ = now;
}

function  checkBettingRange (uint256 _pID,uint256 _eth) 
public
view
returns(bool res) {

    if(plyr_[_pID].totalBet > 0 && plyr_[_pID].roundId > 0){
   
        if((plyr_[_pID].roundId == 1 &&  _eth == 1 * ethWei) || 
            (plyr_[_pID].roundId == 2 &&  _eth == 2 * ethWei) || 
            (plyr_[_pID].roundId == 3 &&  (_eth == 3 * ethWei)) ||
            (plyr_[_pID].roundId == 4 &&  (_eth == 3 * ethWei || _eth == 5 * ethWei)) ||
            (plyr_[_pID].roundId == 5 &&  (_eth == 5 * ethWei || _eth == 10 * ethWei)) ||
            (plyr_[_pID].roundId > 5  &&  (_eth == 10 * ethWei))) {

            res = true;  
        }else{

            res = false;
        }


    }else{
        res = _eth == minbeteth_?true:false;
      
   }
}

function buyCore(uint256 _pID,uint256 _eth)
    private
{
    
   
    checkOut(_pID);
    plyr_[_pID].roundId++;
    require ((plyr_[_pID].totalBet == 0  || plyrReward_[_pID].outStatus) &&  
        checkBettingRange(_pID,_eth),'checkBettingRange false');
    
    
    
    plyrReward_[_pID].outStatus = false;


   uint256 _com = _eth.mul(3)/100;
    if(_com>0){
        bose.transfer(_com);
    }
    
    gBet_ = gBet_.add(_eth);
    gBetcc_= gBetcc_ + 1; 
    
 
    dealwithChampionPot(_pID,_eth);
    plyr_[_pID].totalBet = _eth.add(plyr_[_pID].totalBet);
   
    plyrReward_[_pID].reward = plyrReward_[_pID].reward.add(((_eth.mul(getoutBeishu))/10));

    


    uint256 _curBaseGen = _eth.mul(genRate_) /100;
    plyr_[_pID].baseGen = plyr_[_pID].baseGen.add(_curBaseGen);

    affUpdate(_pID,plyr_[_pID].affId,_curBaseGen,0,1,gOrderId_);

 

    if(!plyr_[_pID].isaffer){
        plyr_[_pID].isaffer = true;
    }
    
    plyr_[_pID].lastReleaseTime = now;
    plyr_[_pID].curOrderId = gOrderId_;
    betHistory_[gOrderId_].pid = _pID;
    betHistory_[gOrderId_].datetime = now;
    betHistory_[gOrderId_].eth = _eth;
    betHistory_[gOrderId_].roundId = plyr_[_pID].roundId;
    gOrderId_++;
    
}

function getPlayerlaByAddr (address _addr)
public
view
returns(uint256,uint256,uint256,uint256,uint256,uint256,string memory,uint256,uint256)
{
    uint256 _pID = pIDxAddr_[_addr];
    
    (uint256 _gen,uint256 _aff,) = getUserRewardByBase(_pID);
    
    uint256 totalGenH =  plyrReward_[_pID].totalGen - plyrReward_[_pID].withDrawEdGen + _gen;
    uint256 totalAffH =  plyrReward_[_pID].totalAff - plyrReward_[_pID].withDrawEdAff + _aff;
 
    return(
        _pID,
        plyrReward_[_pID].reward>(plyr_[_pID].curGen + plyr_[_pID].curAff+_gen+_aff)?plyrReward_[_pID].reward.sub(plyr_[_pID].curGen + plyr_[_pID].curAff+_gen+_aff):0,
        plyrReward_[_pID].totalGen + _gen,
        plyrReward_[_pID].totalAff + _aff,
        totalGenH,
        totalAffH,
        plyr_[_pID].inviteCode,
        plyr_[_pID].baseGen,
        plyr_[_pID].baseAff
           
        
        );


}



function getPlayerlaById (uint256 _pID)
public
view
returns(uint256,address,uint256,uint256,bool,uint256)
{
   require(_pID>0 && _pID < nextId_, "Now cannot withDraw!");
    return(
        plyr_[_pID].affId,
        plyr_[_pID].addr,
        plyr_[_pID].totalBet,
        plyr_[_pID].roundId,
        plyrReward_[_pID].outStatus,
        plyrReward_[_pID].championPot
        );


}

function getuserinfos(uint256 _pID) public view returns(string memory invitecode){
    invitecode = plyr_[plyr_[_pID].affId].inviteCode;
}
function checkInviteCode(string memory _code)  public view returns(uint256 _pID){
    
    _pID = pIDInviteCode_[_code];
    
}

function getsystemMsg()
public
view
returns(uint256 _gbet,uint256 _gcc,uint256 _championPot,uint256 _championRound,uint256 _championEndTime_,uint256 _curchampionMaxUsers,string memory _curchampion,string memory _lastChampion)
{
    return
    (
        gBet_,
        gBetcc_,
        championPot_,
        championRound_,
        championStartTime_+championTime_,
        curchampionMaxUser_,
        plyr_[curchampionPid_].inviteCode,
        plyr_[lastChampionPid_].inviteCode
        
       
        
    );
}
}
