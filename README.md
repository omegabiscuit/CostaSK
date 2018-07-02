# !!! Last update 2017
There is no Masterlooter in BfA so there is no use for this addon anymore.

# Drunkard Suicide Kings

A Suicide Kings loot distribution addon created for <Drunkard> of Bloodscalp. That does not mean it won't work perfectly well for your guild.

One of the main design goals of DSK was ease of use. There are no options to configure. It is intended to work right out of the box. Set up a list via importing one or manually creating it and you are ready to distribute loot.

### Features:

* Two separate lists (normal loot and armor tokens).
* Automatically uses the token list for armor tokens.
* Lists viewable by everyone.
* Gui interface to bid, roll offspec, or pass on items.
* Current winner listed in bidding frame.
* Player's bids, passes, and offspecs listed next to them in the list.
* Ability to copy of lists into and out of WoW.
* Automaticly hands out item to the winner on close bid if avaible (highest bidder or roller)

### Usage:

/dsk will open the list frame. There are two lists: normal gear and armor tokens.

In order to manipulate the lists (add, remove, etc), or opening bidding on an item you must be masterlooter in a raid and a guild officer.

To add someone to a list simply target them and select add. They can be moved up or down the list, removed from the list, or murdered (forced suicide) by selecting the player in the list hitting the appropriate button.

To open bidding on an item simply alt click it. This will open the bidding window on everyone's screen (assuming they also have this installed).

To sync the lists. If you are not the masterlooter and hit sync, the masterlooter will broadcast his list to everyone. If you are the masterlooter and hit sync, all of the officers will send you their lists and yours will be updated. Either way lists are only updated if a newer list is received.

To copy a list out of WoW. Go to the I/E List tab. Select the appropriate list and hit Export. Copy and paste the selected list out of WoW.

To copy a list into WoW. Go to the I/E List tab. Put a list in the appropriate format into the box. Select the appropriate list and hit Import. Note: this will erase the current list.

### Notes:

* ~~An officer is defined by ability to speak in /o. If you can speak in /o you are an officer as far as DSK is concerned.~~ In 7.3 one of the functions used to check for the ability to speak in /o was moved to protected functions and now instead we define officers with ability to edit Officer Notes in the Guild Roster.
* Tier items dropped in the vault will use the normal list. Only the actual armor tokens use the token list.

### TODO:

* Fix issue with addon sometimes not opening bidding until UI is reloaded.
* Add a way to undo/revert a list change/suicide.

**Please disable TradeSkillMaster before copy&pasting Lua errors to me, it makes the Lua error -reports almost impossible to read.**