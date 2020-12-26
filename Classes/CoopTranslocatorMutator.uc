class CoopTranslocatorMutator extends Mutator;

function ModifyPlayer(Pawn me) {
	local int t;
	local bool found;
	local Inventory Inv, Coop, After;

	super.ModifyPlayer(me);
	
	// remove old CoopTranslocator if already have
	t = 0;
	found = false;
	for (Inv = me.Inventory; Inv != None; Inv = Inv.Inventory) {
		if (t++ > 1000) break; // can occasionally get temporary loops in netplay (c) Epic
		if (Inv.isA('CoopTranslocator')) {
			if (Inv.class != class'CoopTranslocator') Inv.Destroy();
			else found = true;
		} else if (Inv.isA('Translocator')) {
			After = Inv;
		}
	}
	if (!found) {
		Coop = me.Spawn(class'CoopTranslocator');
		if (Coop != None) {
			Coop.RespawnTime = 0.0;
			Coop.GiveTo(me);
			Coop.bHeldItem = true;
			Weapon(Coop).SetSwitchPriority(me);
			Coop.AmbientGlow = 0;
			Coop.SetTimer(1.0, true);
			
			// Move CoopTranslocator after Translocator
			if (me.Inventory == Coop && Coop.Inventory != None && After != None) {
				me.Inventory = Coop.Inventory;
				Coop.Inventory = After.Inventory;
				After.Inventory = Coop;
			}
		}
	}
	
	me.bAlwaysRelevant = True; // fix
}

function Mutate(string Command, PlayerPawn Sender) {
	local Inventory Inv;
	
	if (Command ~= "cooptrans disable") {
		for (Inv = Sender.Inventory; Inv != None; Inv = Inv.Inventory) {
			if (Inv.class == class'CoopTranslocator') {
				CoopTranslocator(Inv).DisableTrans();
				break;
			}
		}
	}

	super.Mutate(Command, Sender);
}