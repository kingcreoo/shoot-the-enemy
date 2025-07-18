## Terminology:
Settings file - A file in the source code, /src/ReplicatedStorage/init.luau, that contains data on various items in the game.
Lobby - The place where players spawn when first joining the game. The lobby includes areas to buy new items and also portals that let them select a level to play from that specific world.
World - A distinct universe/dimension with levels of it's own. A player may need to complete one world to gain access to another. Portals to each world are located inside the lobby.
Level's model - The basic play area of a level in 3D space in roblox studio.
Team - The player's team of soldiers that they control within a level.

## The settings file, and how to use/reference from it

The settings file, located at /src/ReplicatedStorage/init.luau, is the primary base for any kind of data that code may need to reference. This includes but is not limited to: data that new players are to be given, data regarding each enemy type, and data regarding each level and what to spawn(and when).

Example of some code that already uses the settings file: When the player requests to play a level (and the server accepts said request), the player's client references the settings file to generate the level's model, and to spawn each of the level's enemies at their proper time.

Example of how to expand upon the settings file: When creating a new type of enemy, it's stats and configs are to be stored in the settings file. When creating a new level, all of it's configurations are to be stored in the settings file.

Clarification of certain settings file elements:
- The enemy format under a specific level is as follows:
{"Grunt", 1, 1, Vector3.new(0,0,0)}
{EnemyType, SpawnTimeNumber, SpawnLaneNumber, Offset from that specific lane's spawn part}

## Location of various items inside of ROBLOX STUDIO

All remote events are stored under ReplicatedStorage.Events
All remote functions are stored under ReplicatedStorage.Functions
All bindable events & functions are stored under ReplicatedStorage.Bindables

All enemy types are stored under ReplicatedStorage.Enemies
    Enemies are a model type, and have these specific parts as children
        - An animation controller (with Animator as a child)
        - NHRMidSection (which is the primarypart)
        - A weapon (not by default, but can be inserted. Weapons also have a "Fire" part as a child where bullets spawn from)
All boss types are stored under ReplicatedStorage.Bosses
All entity types are stored under ReplicatedStorage.Entities (Ex: SmallBullet, LargeBullet, StandardExplosion)
All levels are stored under ReplicatedStorage.Levels. Each world has it's own folder under ReplicatedStorage.Levels ex: "TactileWorld" where it's levels reside under
All weapons are stored under ReplicatedStorage.Weapons
All animations are stored under ReplicatedStorage.Animations