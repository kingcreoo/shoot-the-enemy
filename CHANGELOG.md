# Changelog
A brief overview of implemented items, a description of their functionality, and a clarification of any important points

## UI Management

All GUI logic lives client-side in UIHandler (state machine) and UIAnimations (tween presets). UIHandler opens/closes screens like the Level Selector, and future Operator Ability button, guaranteeing only one primary panel is active at a time.

## Load screens

When the game boots the LoadScreenHandler takes over the camera and shows a full-screen panel with animated dots, a progress bar, and a fade-to-clear sequence. It polls ReplicatedFirst streaming stats every 0.1 s and updates the label ("342 / 10 000 parts loaded"). The screen auto-dismisses when 100 % is reached or the player taps Skip—whichever comes first—then hands control back to the lobby.

## Player data

We outsource all player data datastores to a Data module (under serverscriptservice). This way the server can simply run Data:Get(Player) rather than having to handle the data store services itself. Data module uses a simple DeepCopy helper to duplicate nested tables. Caches the timestamp of the last successful save in Saves[PlayerName] to throttle writes.

## Level selection

Each world has a portal inside of the lobby. The portal is entirely aesthetic. When the player comes within a certain range of the portal, they trigger a proximityprompt which opens the level selection UI for that particular world. Inside there are icons and buttons to the levels they can play or need to unlock. They select levels from here. After clicking on a level's button, they will eventually be prompted to pick a skin and operator, for now they immediately fire the server. The server checks if the player has unlocked this level. If yes, the client will generate the level (THE SERVER WILL NOT) and start the level following it's information found in settings.

## Player controls

The players controls are strictly from left to right, to aim there team down the line to fire at enemies coming towards them. Eventually there may be a button on screen added to use the operator's ability. It will also be important for the player to properly position their team to collect rewards that come towards them (or obstactles that result in lost soldiers)

## Team management

The player will start off with a certain amount of soldier's in it's team, which is designated inside of the level's settings in the settings file. Soldiers cannot be harmed by the enemies by standard soldiers, usually only tanks or other types that shoot at the team can harm soldiers. The player can add or remove soldiers via obstacles, a sort of neon/transparent wall that comes towards the player's team. One side is red and the other is blue, red removes soldiers and blue adds soldiers. Obstacles may take other shapes or sizes.

## Enemy registry

EnemyRegistry is the per-level directory of every live enemy. On creation it reads the level’s enemy list from Settings.LEVEL_DATA, clones the required models from ReplicatedStorage.Enemies, and spawns a matching controller object (e.g., Grunt.new). Each model/controller pair is stored in self.Registry, giving the game a single place to query positions, hit-box sizes, and movement data (GetEnemyInfo), to detach or destroy enemies (Remove, Cleanup), and to hand the whole table over to Bullet or Level logic without searching the workspace.

## Enemy spawning

Enemies are spawned inside of distinct lanes, that run from the players team to the spawn zone of enemies. Each lane has a cosmetic 'factory' building or spawn building. Some lanes may be smaller than others like lanerunner types or laneswapper types. Each enemy unit will have it's own enemy profile inside of the level's settings. So if we want to spawn a group of enemies as a sort of 'unit' (as displayed to the player) it is actually deployed as three individual enemies with offsets.

Enemies always spawn at the same times for each level. Levels don't have any variation within themself. Enemies never pass other enemies in their own lane. Most enemies strictly stay within their own lane (except laneswapper types, which may only appear in specific levels)

## Enemy action loops

Each enemy has an action loop (located in their settings in the settings file) that shows what they will be doing and when(based off of their spawn time). This allows for us to calculate where enemies will be at a particular time based off of their spawn time. This is particularly useful for bullet creation. For example, the basic grunt unit just has one action: a march to the enemies team. Another example, a tank unit marches for a few seconds, then fires a shot, repeat until it reaches the end. Action loops dont repeat they will always go through all of their steps just once. The format is as follows:

local ACTION_LOOP = {
    [1] = {"March", 22, 1}
}

    [stepnumber] = {action_type, how long the action will take, the fraction of the distance between where the enemy spawns and its goal}

## Entity pooling

Bullets and explosions are pooled to keep performance high. At the beginning of a level, the levelcontroller will create an entityhandler module which will create the pooling of bullets/explosions, or any other entities that may be introduced down the line. It is still the responsibility of the bullethandler to calculate the bullet's target and to animate the bullet.

## Bullet creation

Unlike how ROBLOX commonly uses raycasts or projectile bullets, this game uses neither. Every *firerate* seconds, each soldier spawns a bullet from their weapon's "Fire" part.

A calculation is ran to see what enemies are valid to be hit and what enemy will be hit first (if any at all). Based off that calculation we run a tween and animate the bullet. With this method we can keep performance high. This is possible because enemies run on a fixed action loop.