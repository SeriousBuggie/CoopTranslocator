class CoopTranslocator extends Translocator;

var bool bCanTranslocate;
var Pawn TargetPawn;
var PlayerReplicationInfo TargetPRI;
var localized String Selected;
var localized String TranslocateFailed;
var localized String PlayerMovesUp;
var localized String PlayerDisableTele;
var localized string NoSpaceAbove;
var Font FirstFont;
var Pawn player[32];

replication {
	reliable if (Role == ROLE_Authority)
		TargetPRI;
}

state Active {
	function BeginState() {
		super.BeginState();
		TargetPawn = None;
		bTTargetOut = false;
	}
}

state Idle {
	function bool PutDown() {
		TargetPawn = None;
		bTTargetOut = false;
		return super.PutDown();
	}
}

event Tick (float delta) {
	if (bDeleteMe) return;
	if (Pawn(Owner) == None || Pawn(Owner).bDeleteMe) {
		Destroy();
		return;
	}
	if ((Level.Game).bGameEnded) Destroy();
	bTTargetOut = TargetPawn != None;
	bHideWeapon = TargetPawn != None;
}

function Fire(float Value) {
	if (Pawn(Owner).bAltFire != 0) {
		ReturnToPreviousWeapon();
		return;
	}
	if (bCanTranslocate) {
		PlayAnim('Throw', FireAdjust, 0.1);
		SelectTarget();
	}
	if (IsInState('Active')) GotoState('Idle');
}

function AltFire(float Value) {
	if (Pawn(Owner).bFire != 0) {
		ReturnToPreviousWeapon();
		return;
	}
	if (bCanTranslocate) {
		PlayAnim('Thrown', 1.2, 0.1);
		Translocate();
	}
	if (IsInState('Active')) GotoState('Idle');
}

simulated function bool ClientFire(float Value) {
	return true;
}

static function bool canBeTarget(CoopTranslocator trans, Pawn P) {
	if (P != None && P.PlayerReplicationInfo != None && ((P.isA('PlayerPawn') && !P.IsA('Spectator') && !P.IsA('Camera')) || P.isA('Bot') || P.isA('Bots')) && P != trans.Owner) {
		P.bAlwaysRelevant = True; // fix
		return true;
	}
	return false;
}

function SelectTarget() {
	local Pawn P;
	local int i, cnt;

	if (TargetPawn == None && TargetPRI != None) P = Pawn(TargetPRI.Owner);
	if (!canBeTarget(self, P)) { // need find next target
		P = None;
		cnt = BuildPlayersList(self);
		
		if (TargetPawn != None) {
			for (i = 0; i < cnt; i++) {
				if (player[i] == TargetPawn) {
					P = player[(i + 1) % cnt];
					break;
				}
			}
		}
		if (P == None) P = player[0];
	}

	if (P != None) {
		TargetPawn = P;
		TargetPRI = P.PlayerReplicationInfo;
		Owner.PlaySound(FireSound, SLOT_Misc, 4 * Pawn(Owner).SoundDampening);
		bTTargetOut = True;
		Pawn(Owner).ClientMessage(Selected @ TargetPRI.PlayerName $ "."); // fall back if tiles not draw by some reason
	} else {
		TargetPawn = None;
		TargetPRI = None;
		Owner.PlaySound(AltFireSound, SLOT_Misc, 4 * Pawn(Owner).SoundDampening);
		bTTargetOut = False;
	}
}

function Translocate() {
	local Vector X, Y, Z;
	local Vector Start, Dest;
	local string Deny;
	
	if (TargetPawn == None || TargetPawn.Health < 0) {
		Owner.PlaySound(AltFireSound, SLOT_Misc, 4 * Pawn(Owner).SoundDampening);
		return;
	}

	GetAxes(TargetPawn.Rotation.Yaw * rot(0, 1, 0), X, Y, Z); // get rotation only over Z axis
	Dest = TargetPawn.Location + 
		TargetPawn.CollisionHeight * vect(0, 0, 2.5) - // make location above target
		TargetPawn.CollisionRadius * X; // and little at back

	Deny = "";
	if (TargetPawn.Base != None && TargetPawn.Base.Velocity.Z > 0) Deny = TargetPawn.PlayerReplicationInfo.PlayerName @ PlayerMovesUp;
	if (TargetPawn.PlayerReplicationInfo.GetPropertyText("bCoopTeleDisable") == "True") Deny = TargetPawn.PlayerReplicationInfo.PlayerName @ PlayerDisableTele;

	Start = Owner.Location;
	if (Deny == "") {
		if (Owner.SetLocation(Dest)) {
			if (!Owner.Region.Zone.bWaterZone) Owner.SetPhysics(PHYS_Falling);
			PlayerPawn(Owner).ClientSetRotation(TargetPawn.Rotation.Yaw * rot(0, 1, 0)); // set rotation same as target for Z axis, for allow press back for avoid team fire
			Owner.Velocity.X = 0;
			Owner.Velocity.Y = 0;
			Level.Game.PlayTeleportEffect(Owner, true, true);
			SpawnEffect(Start, Dest);
			TargetPawn = None;
			bTTargetOut = False;
		} else {
			Deny = NoSpaceAbove @ TargetPawn.PlayerReplicationInfo.PlayerName $ ".";
		}
	}
	if (Deny != "") {
		Pawn(Owner).ClientMessage(TranslocateFailed @ Deny);
		Owner.PlaySound(AltFireSound, SLOT_Misc, 4 * Pawn(Owner).SoundDampening);
	}
}

simulated function PlayPostSelect() {
	super(TournamentWeapon).PlayPostSelect();
}

static function int BuildPlayersList(CoopTranslocator trans) {
	local Pawn tp;
	local int cnt;
	
	cnt = 0;
	if (trans.Level.Role == ROLE_Authority && trans.Level.PawnList != None) {
		for (tp = trans.Level.PawnList; tp != None; tp = tp.NextPawn) {
			if (!canBeTarget(trans, tp)) continue;
			trans.player[cnt++] = tp;
		}
	} else {
		forEach trans.AllActors(class'Pawn', tp) {
			if (!canBeTarget(trans, tp)) continue;
			trans.player[cnt++] = tp;
		}
	}
	
	if (cnt > 0) SortPlayers(trans, 0, cnt - 1);
	return cnt;
}

// http://www.unreal.ut-files.com/3DEditing/Tutorials/unrealwiki-offline/quicksort.html
static Function SortPlayers(CoopTranslocator trans, Int Low, Int High) { //Sortage
//  low is the lower index, high is the upper index
//  of the region of array a that is to be sorted
	local Int i,j;
	local String x;
	Local Pawn tmp;

	i = Low;
	j = High;
	x = trans.player[(Low+High)/2].PlayerReplicationInfo.PlayerName;

	do { //  partition
		while (trans.player[i].PlayerReplicationInfo.PlayerName < x) i += 1; 
		while (trans.player[j].PlayerReplicationInfo.PlayerName > x) j -= 1;
		if (i <= j) {
			tmp = trans.player[j];
			trans.player[j] = trans.player[i];
			trans.player[i] = tmp;
			
			i += 1; 
			j -= 1;
		}
	} until (i > j);

	//  recursion
	if (low < j) SortPlayers(trans, low, j);
	if (i < high) SortPlayers(trans, i, high);
}

simulated function PostRender(Canvas C) {
	local Actor actor;	
	local int i, j, cnt, offX, offY, tiles, tileX, tileY, x, y, size, visible, start, end, skip;
	local string label;
	local ChallengeHUD HUD;
	
	if (!bTTargetOut) {		
		if (true) { // draw texture for distinguish CoopTranslocator from usual translocator
			y = c.ClipY/8;
			C.Style = ERenderStyle.STY_Translucent;
			C.SetPos(c.ClipX/16, c.ClipY - y);
			C.DrawRect(Texture'UnrealShare.MenuBarrier', C.ClipX*3/8, y);
		}
		return;
	}
	
	if (FirstFont == None) FirstFont = class'FontInfo'.Static.GetStaticSmallFont(C.ClipX);
	if (FirstFont != C.Font) C.Font = FirstFont;
	C.Style = ERenderStyle.STY_Normal;
	
	cnt = BuildPlayersList(self);
	
	HUD = ChallengeHUD(PlayerPawn(Owner).myHUD);
	if (HUD != None) {
		offY = 63.5*HUD.Scale;
	}

	tiles = 2;
	if (cnt > 3) tiles = 3;
	if (cnt > 8) tiles = 4;
	tileX = c.ClipX - 2*offX;
	tileY = c.ClipY - 2*offY;
	tiles = Max(1, Min(Min(tiles, tileX/320), tileY/196)); // 320*196 at least
	tileX = tileX/tiles;
	tileY = tileY/tiles;

	j = -1;
	for (i = 0; i < cnt; i++) {
		if (player[i].PlayerReplicationInfo == TargetPRI) {
			j = i;
			break;
		}
	}
	
	skip = 1;
	if (tiles == 1) skip = 0;
	
	visible = tiles*tiles - skip;
	start = Max(Min(j, cnt - visible), 0);
	end = Min(start + visible, cnt);

	if (PlayerPawn(Owner) == C.ViewPort.Actor) { // me
		actor = PlayerPawn(Owner).ViewTarget;
		PlayerPawn(Owner).ViewTarget = self; // for view self
	}
	for (i = start; i < end; i++) {
		x = offX + ((i - start + skip) % tiles)*tileX;
		y = offY + ((i - start + skip)/tiles)*tileY;
		C.DrawPortal(x, y, tileX, tileY, player[i], player[i].Location - 100*(vect(1,0,0) >> player[i].Rotation), player[i].Rotation);
		if (j == i) { // selection
			size = 5;
			C.DrawColor.R = 255; C.DrawColor.G = 0; C.DrawColor.B = 0;
			C.SetPos(x, y + 20);
			C.DrawRect(Texture'Botpack.AmmoCountJunk', TileX, size);
			C.SetPos(x, y + TileY - size);
			C.DrawRect(Texture'Botpack.AmmoCountJunk', TileX, size);
			C.SetPos(x, y + 20);
			C.DrawRect(Texture'Botpack.AmmoCountJunk', size, TileY - 20 - size);
			C.SetPos(x + TileX - size, y + 20);
			C.DrawRect(Texture'Botpack.AmmoCountJunk', size, TileY - 20 - size);
		}
		C.SetPos(x, y);
		C.DrawColor.R = 0; C.DrawColor.G = 0; C.DrawColor.B = 0;
		C.DrawRect(Texture'Botpack.AmmoCountJunk', TileX, 20);
		C.SetPos(x, y);
		C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 0;
		label = " " $ player[i].PlayerReplicationInfo.PlayerName $ " (" $ 
			int(player[i].PlayerReplicationInfo.Score) $ ") " $ player[i].Health $ "hp";
		if (player[i].Weapon != None) {
			if (player[i].Weapon.ItemName != "") {
				label = label @ player[i].Weapon.ItemName;
			} else {
				label = label @ player[i].Weapon.class.name;
			}
		}
		C.DrawText(label);
	}
	if (PlayerPawn(Owner) == C.ViewPort.Actor) { // me
		PlayerPawn(Owner).ViewTarget = actor; // restore
	}
}

defaultproperties {
	bPointing=False
	bCanTranslocate=True
	Selected="Translocate target is"
	TranslocateFailed="Translocate failed:"
	PlayerMovesUp="goes up on lift."
	PlayerDisableTele="disabled the teleport."
	NoSpaceAbove="not enough space above"
	bTTargetOut=False
	bOwnsCrosshair=True
	FireSound=Sound'UnrealShare.Eightball.SeekLock'
	AltFireSound=Sound'UnrealShare.Eightball.SeekLost'
}