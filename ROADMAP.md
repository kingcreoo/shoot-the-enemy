# ROADMAP
A short list of major to-dos for the game

## Loss and victory conditions

The only victory condition is defeating all the enemies, including the boss. There are two loss conditions. One is losing all of your HEARTS. Players will start a level with 5 hearts. When an enemy reaches the end, the player loses a heart. The other loss condition is losing all of the soldiers and the operator on a player's team. Player can lose soldiers and operators when a tank or artillery type fires at the palyer's team, or when the player's team goes through obstacles and perhaps goes through the wrong 'red' side that removes soldiers.

## In-level security

The server is to randomly request data from the client's level controller ~4 times during a level. The client will return data on how many enemies have been killed, when the bullets landed, etc. The server will validate this info to check for cheaters.