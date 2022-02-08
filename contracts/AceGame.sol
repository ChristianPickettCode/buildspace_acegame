// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./libraries/Base64.sol";

import "hardhat/console.sol";

contract AceGame is ERC721 {
  struct CardAttributes {
    uint256 cardIndex;
    string name;
    string imageURI;
    uint256 hp;
    uint256 maxHp;
    uint256 attackDamage;
    uint256 tokenId;
  }

  struct Boss {
    string name;
    string imageURI;
    uint256 hp;
    uint256 maxHp;
    uint256 attackDamage;
  }

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  CardAttributes[] defaultCards;

  mapping(uint256 => CardAttributes) public nftHolderAttributes;

  mapping(address => uint256[]) public nftHolders;

  Boss public boss;

  event CardNFTMinted(address sender, uint256 tokenId, uint256 cardIndex);
  event AttackComplete(uint256 newBossHp, uint256 newPlayerHp, uint256 tokenId);

  constructor(
    string[] memory cardNames,
    string[] memory cardImageURIs,
    uint256[] memory cardHp,
    uint256[] memory cardAttackDmg,
    string memory bossName,
    string memory bossImageURI,
    uint256 bossHp,
    uint256 bossAttackDamage
  ) ERC721("Kings", "KING") {
    boss = Boss({
      name: bossName,
      imageURI: bossImageURI,
      hp: bossHp,
      maxHp: bossHp,
      attackDamage: bossAttackDamage
    });

    console.log(
      "Done initializing boss %s w/ HP %s, img %s",
      boss.name,
      boss.hp,
      boss.imageURI
    );

    for (uint256 i = 0; i < cardNames.length; i++) {
      defaultCards.push(
        CardAttributes({
          cardIndex: i,
          name: cardNames[i],
          imageURI: cardImageURIs[i],
          hp: cardHp[i],
          maxHp: cardHp[i],
          attackDamage: cardAttackDmg[i],
          tokenId: _tokenIds.current()
        })
      );

      CardAttributes memory c = defaultCards[i];
      console.log(
        "Done initializing %s w/ HP %s, img %s",
        c.name,
        c.hp,
        c.imageURI
      );
    }
    _tokenIds.increment();
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    CardAttributes memory cardAttributes = nftHolderAttributes[_tokenId];

    string memory strHp = Strings.toString(cardAttributes.hp);
    string memory strMaxHp = Strings.toString(cardAttributes.maxHp);
    string memory strAttackDamage = Strings.toString(
      cardAttributes.attackDamage
    );

    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        cardAttributes.name,
        " -- NFT #: ",
        Strings.toString(_tokenId),
        '", "description": "This is an NFT that lets people play in the game King of Aces!", "image": "',
        cardAttributes.imageURI,
        '", "attributes": [ { "trait_type": "Health Points", "value": ',
        strHp,
        ', "max_value":',
        strMaxHp,
        '}, { "trait_type": "Attack Damage", "value": ',
        strAttackDamage,
        "} ]}"
      )
    );

    string memory output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );

    return output;
  }

  function mintCardNFT(uint256 _cardIndex) external {
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);

    nftHolderAttributes[newItemId] = CardAttributes({
      cardIndex: _cardIndex,
      name: defaultCards[_cardIndex].name,
      imageURI: defaultCards[_cardIndex].imageURI,
      hp: defaultCards[_cardIndex].hp,
      maxHp: defaultCards[_cardIndex].maxHp,
      attackDamage: defaultCards[_cardIndex].attackDamage,
      tokenId: newItemId
    });

    console.log(
      "Minted NFT w/ tokenId %s and cardIndex %s",
      newItemId,
      _cardIndex
    );

    nftHolders[msg.sender].push(newItemId);

    _tokenIds.increment();
    emit CardNFTMinted(msg.sender, newItemId, _cardIndex);
  }

  function attackBoss(uint256 tokenId) public {
    // Get the state of the player's NFT.
    CardAttributes storage player = nftHolderAttributes[tokenId]; // storage updates the value in global state (memory only does locally)
    console.log(
      "\nPlayer w/ character %s about to attack. Has %s HP and %s AD",
      player.name,
      player.hp,
      player.attackDamage
    );
    console.log(
      "Boss %s has %s HP and %s AD",
      boss.name,
      boss.hp,
      boss.attackDamage
    );

    // Make sure the player has more than 0 HP.
    require(player.hp > 0, "Error: card must have HP to attack boss.");

    // Make sure the boss has more than 0 HP.
    require(boss.hp > 0, "Error: boss must have HP to attack boss.");

    // Allow player to attack boss.
    if (boss.hp < player.attackDamage) {
      boss.hp = 0;
    } else {
      boss.hp = boss.hp - player.attackDamage;
    }
    // Allow boss to attack player.
    if (player.hp < boss.attackDamage) {
      player.hp = 0;
    } else {
      player.hp = player.hp - boss.attackDamage;
    }

    console.log("Player attacked boss. New boss hp: %s", boss.hp);
    console.log("Boss attacked player. New player hp: %s\n", player.hp);

    emit AttackComplete(boss.hp, player.hp, tokenId);
  }

  function checkIfUserHasNFT() public view returns (CardAttributes[] memory) {
    uint256 numOfNfts = nftHolders[msg.sender].length;
    if (numOfNfts > 0) {
      CardAttributes[] memory arr = new CardAttributes[](numOfNfts);
      for (uint256 index = 0; index < numOfNfts; index++) {
        uint256 tokenId = nftHolders[msg.sender][index];
        arr[index] = nftHolderAttributes[tokenId];
      }
      return arr;
    } else {
      CardAttributes[] memory emptyArray;
      return emptyArray;
    }
  }

  function getAllDefaultCards() public view returns (CardAttributes[] memory) {
    return defaultCards;
  }

  function getBoss() public view returns (Boss memory) {
    return boss;
  }

  function changeHolder(
    address from,
    address to,
    uint256 tokenId
  ) private {
    for (uint256 i = 0; i < nftHolders[from].length; i++) {
      if (nftHolders[from][i] == tokenId) {
        nftHolders[to].push(tokenId);
        nftHolders[from][i] = nftHolders[from][nftHolders[from].length - 1];
        nftHolders[from].pop();
        return;
      }
    }
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _transfer(from, to, tokenId);
    changeHolder(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _safeTransfer(from, to, tokenId, _data);
    changeHolder(from, to, tokenId);
  }
}
