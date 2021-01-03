-=[ CoopTranslocator for MonsterHunt ]=-

A special "weapon" that allows you to teleport to another hunter.

Originally developed by Gust (?). I am not sure.

Use Fire to start select teammate.
Use AltFire to translocate to selected teammate.
If translocate fail you can try again and again until it will be success.
If you press Fire+AltFire previous weapon will be selected.

On tele usually better press back for avoid friendly fire by your teammate.

Count of preview tiles (up to 15) depends from client resolution. Each tile at least 320*240 px.

Difference from original (by Gust):
1. You can preview players. And their hp, score and current weapon.
2. Green texture near teleporter for distinguish from usual teleporter.
3. Fixed a lot of bugs.
4. If player moves up (in lift or jump). (For prevent kill him or spoil trajectory of movement)
5. If string(PRI.bCoopTeleDisable) == "True" you can not tele. (For extends by some server via function "disable/enable tele to me")
6. If you can not tele - description provided.
7. Clean up code.
8. Set rotation to target.
9. Place to tele is up and little back target.
10. Press Fire + Alt fire for return back to previous weapon.
11. The player can disable teleportation to himself via the "mutate cooptrans disable" command. The administrator can disable this behavior in server UnrealTournament.ini.
If a player has disabled teleportation to himself, then he himself cannot teleport to other players.
To enable, use the command "mutate cooptrans enable". After the delay, the translocator will be turned on, and you will receive a corresponding message.
12. And a lot other small improvements.

-=[ Mutator ]=-

Each player get CoopTranslocator at start.

If other CoopTranslocator found in Inventory then it is destroyed.

-=[ Install ]=-

As usual - copy .u and .int files in System UT directory. Nothing more.

Use on server - do not forget add package to ServerPackages.

Source can be built with UMake.

You can set options in UnrealTournament.ini:

[CoopTranslocator7.CoopTranslocator]
;Mutate command. Use empty string to turn off disable feature.
Command=cooptrans
;Delay for use after enable.
DisableUseTime=30

-=[ Credits ]=-

If you need something go to ut99.org
