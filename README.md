**Version 3.5**
  - Added Stashing of items based on your "Keep Greater Affix Count" slider
    set your threshold to your desired amount of GA's to keep, and set your keep items to stash and the script will salvage items < the keep greater affix count and it will stash the items that are > or = to your threshold. 
  - fixed stupid ladder
    Script will now look for any traversal actor that is within 5 units of the players Z height, and find a walkeable point close to it in order to path to it using explorer and A*, once close it should go down the stupid ladder
  - tweaked gui to be easier, probably wont help. please instruct others to read the readme / pinned posts / tooltips



**Version 2.0**
  -added max pit time slider 
  
  - exits pit when time in pit reaches reset time

  - improved find central unexplored target (main target setting function, now utilizes dbscan algo to cluster unexplored points for navigating to clusters instead of finding the center of all unexplored points
  - improved explored mode target setting (should prioritize setting a target <90 degrees from last target to prevent bouncing between two points)
  - improved move to target for explored mode to prioritize moving to unexplored points when one is found within target distance range) 



Beta Version 1.0
- added town salvage in cinnegar
- added town repair in cinnegar
- added town sell in cinnegar
- tweaked finish pit and exit pit to reduce chances of missing loot (neers autolooter is still highly recomended) 



Beta Version 0.15
-Added path smooting slider
-Added option to loot or do nothing (use neers autolooter if you disable loot) 
-Added navigation to start location for boss room 


Beta Version 0.14
-fixed stuck while kill monsters active
-changed grid size to 1.5 (again) should improve performance at the cost of a few more stucks, but should get unstuck. 


Beta Version 0.13
-fixed bug with explored target finding
-improved target selection to help target portal rooms with close walls. 


Beta Version 0.12
-changed path filtering 
if you find yourself getting stuck try editing {  if angle > math.rad(40) then } to a lower number and see if that fixes it. 
 

Current Beta version 
-grid size 1
performance hit, but should prevent stuck in numerous cases. 

