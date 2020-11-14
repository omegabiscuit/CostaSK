

# Costa Suicide Kings

A version of DrunkardSK for Shadowlands, CostaSK is a Suicide Kings loot distribution addon created for &lt;Costa&gt; of Stormrage.

Check out DrunkardSK for the classic version.

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

`/csk` will open the list frame. There are two lists: normal gear and armor tokens.

In order to manipulate the lists (add, remove, etc), or opening bidding on an item you must be masterlooter in a raid and a guild officer.

To add someone to a list simply target them and select add. They can be moved up or down the list, removed from the list, or murdered (forced suicide) by selecting the player in the list hitting the appropriate button.

To open bidding on an item simply alt click it. This will open the bidding window on everyone's screen (assuming they also have this installed).

To sync the lists. If you are not the masterlooter and hit sync, the masterlooter will broadcast his list to everyone. If you are the masterlooter and hit sync, all of the officers will send you their lists and yours will be updated. Either way lists are only updated if a newer list is received.

To copy a list out of WoW. Go to the I/E List tab. Select the appropriate list and hit Export. Copy and paste the selected list out of WoW.

To copy a list into WoW. Go to the I/E List tab. Put a list in the appropriate format into the box. Select the appropriate list and hit Import. Note: this will erase the current list.

### Notes:

* An officer is defined by ability to speak in `/o`. If you can speak in `/o` you are an officer as far as CSK is concerned.
* Tier items dropped in the vault will use the normal list. Only the actual armor tokens use the token list.

### TODO:

* Fix issue with addon sometimes not opening bidding until UI is reloaded.
* Add a way to undo/revert a list change/suicide.
