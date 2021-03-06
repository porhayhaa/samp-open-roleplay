#include <YSI\y_hooks>

new PlayerText:Unscrambler_PTD[MAX_PLAYERS][7]; 

new gLastCar[MAX_PLAYERS];
new gPassengerCar[MAX_PLAYERS];

static const UnscrambleWord[][] = {
	"SPIDER", "DROP", "HIRE", "EARTH", "GOLD", "HEART", "FLOWER", "KNIFE",
	"POOL", "BEACH", "HEEL", "APPLE", "ART", "BEAN", "BEHIND", "AWAY",
	"COOKIE", "DANCE", "SALE", "SEXY", "BULLET", "GRAPE", "GROUND", "FLIP", "DIRT",
	"PRIDE", "AROUSE", "SOUP", "CIRCUS", "VERBA", "RENT", "REFUND", "HUMAN", "ANIMAL",
	"SNOOP", "FOUR", "TURKEY", "HOLE", "HUMOR"
}
;

static stock g_arrVehicleNames[][] = {
    "Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel", "Dumper", "Firetruck", "Trashmaster",
    "Stretch", "Manana", "Infernus", "Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam",
    "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BF Injection", "Hunter", "Premier", "Enforcer",
    "Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach",
    "Cabbie", "Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral", "Squalo", "Seasparrow",
    "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed", "Yankee", "Caddy", "Solair",
    "Berkley's RC Van", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider", "Glendale", "Oceanic",
    "Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy", "Hermes", "Sabre", "Rustler", "ZR-350", "Walton",
    "Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage", "Dozer", "Maverick", "News Chopper", "Rancher",
    "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking", "Blista Compact", "Police Maverick",
    "Boxville", "Benson", "Mesa", "RC Goblin", "Hotring Racer A", "Hotring Racer B", "Bloodring Banger", "Rancher",
    "Super GT", "Elegant", "Journey", "Bike", "Mountain Bike", "Beagle", "Cropduster", "Stunt", "Tanker", "Roadtrain",
    "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra", "FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck",
    "Fortune", "Cadrona", "FBI Truck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer", "Remington", "Slamvan",
    "Blade", "Streak", "Freight", "Vortex", "Vincent", "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder",
    "Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada", "Yosemite", "Windsor", "Monster", "Monster",
    "Uranus", "Jester", "Sultan", "Stratum", "Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito",
    "Freight Flat", "Streak Carriage", "Kart", "Mower", "Dune", "Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30",
    "Huntley", "Stafford", "BF-400", "News Van", "Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club",
    "Freight Box", "Trailer", "Andromada", "Dodo", "RC Cam", "Launch", "LSPD Cruiser", "SFPD Cruiser", "LVPD Cruiser",
    "Police Rancher", "Picador", "S.W.A.T. Tank", "Alpha", "Phoenix", "Glendale", "Sadler", "Luggage", "Luggage", "Stairs",
    "Boxville", "Tiller", "Utility Trailer"
};

stock HasNoEngine(vehicleid)
{
	switch(GetVehicleModel(vehicleid))
	{
		case 481, 509, 510: return 1;
	}
	return 0;
}

stock ReturnVehicleName(vehicleid)
{
	new
		model = GetVehicleModel(vehicleid),
		name[32] = "None";

    if (model < 400 || model > 611)
	    return name;

	format(name, sizeof(name), g_arrVehicleNames[model - 400]);
	return name;
}

stock ReturnVehicleModelName(model)
{
	new
	    name[32] = "None";

    if (model < 400 || model > 611)
	    return name;

	format(name, sizeof(name), g_arrVehicleNames[model - 400]);
	return name;
}

stock ResetVehicleVars(vehicleid)
{
	if(vehicleid == INVALID_VEHICLE_ID)
		return 0;
	
	vehicleData[vehicleid][eVehicleDBID] = 0; 
	vehicleData[vehicleid][eVehicleOwnerDBID] = 0;
	vehicleData[vehicleid][eVehicleFaction] = 0;

	vehicleData[vehicleid][eVehicleFuel] = 100.0; 
	vehicleData[vehicleid][eVehicleEngineStatus] = false;
	vehicleData[vehicleid][eVehicleLights] = false;
	return 1;
}

stock ToggleVehicleEngine(vehicleid, bool:enginestate)
{
	new engine, lights, alarm, doors, bonnet, boot, objective;

	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
	SetVehicleParamsEx(vehicleid, enginestate, lights, alarm, doors, bonnet, boot, objective);
	return 1;
}

stock ToggleVehicleAlarms(vehicleid, bool:alarmstate, time = 5000)
{
	new engine, lights, alarm, doors, bonnet, boot, objective;
 
	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
	SetVehicleParamsEx(vehicleid, engine, lights, alarmstate, doors, bonnet, boot, alarmstate);
	
	if(alarmstate) defer OnVehicleAlarm[time](vehicleid);
	return 1;
}

stock ScrambleWord(const str[])
{
	new scam[16];
    strcat(scam, str);
	new tmp[2], num, len = strlen(scam);

	while(strequal(str, scam)) {
		for(new i=0; scam[i] != EOS; ++i)
		{
			num = random(len);
			tmp[0] = scam[i];
			tmp[1] = scam[num];
			scam[num] = tmp[0];
			scam[i] = tmp[1];
		}
	}
	return scam;
}

stock CreateUnscrambleTextdraw(playerid, bool:showTextdraw = true)
{
	if(showTextdraw)
	{
		//Unscrambler Textdraws:
		Unscrambler_PTD[playerid][0] = CreatePlayerTextDraw(playerid, 199.873275, 273.593383, "<UNSCRAMBLED_WORD>");
		PlayerTextDrawLetterSize(playerid, Unscrambler_PTD[playerid][0], 0.206330, 1.118813);
		PlayerTextDrawAlignment(playerid, Unscrambler_PTD[playerid][0], 1);
		PlayerTextDrawColor(playerid, Unscrambler_PTD[playerid][0], -1);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][0], 0);
		PlayerTextDrawSetOutline(playerid, Unscrambler_PTD[playerid][0], 1);
		PlayerTextDrawBackgroundColor(playerid, Unscrambler_PTD[playerid][0], 255);
		PlayerTextDrawFont(playerid, Unscrambler_PTD[playerid][0], 2);
		PlayerTextDrawSetProportional(playerid, Unscrambler_PTD[playerid][0], 1);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][0], 0);
		PlayerTextDrawShow(playerid, Unscrambler_PTD[playerid][0]);

		Unscrambler_PTD[playerid][1] = CreatePlayerTextDraw(playerid, 137.369461, 273.593383, "/unscramble");
		PlayerTextDrawLetterSize(playerid, Unscrambler_PTD[playerid][1], 0.206330, 1.118813);
		PlayerTextDrawAlignment(playerid, Unscrambler_PTD[playerid][1], 1);
		PlayerTextDrawColor(playerid, Unscrambler_PTD[playerid][1], -490707969);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][1], 0);
		PlayerTextDrawSetOutline(playerid, Unscrambler_PTD[playerid][1], 1);
		PlayerTextDrawBackgroundColor(playerid, Unscrambler_PTD[playerid][1], 255);
		PlayerTextDrawFont(playerid, Unscrambler_PTD[playerid][1], 2);
		PlayerTextDrawSetProportional(playerid, Unscrambler_PTD[playerid][1], 1);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][1], 0);
		PlayerTextDrawShow(playerid, Unscrambler_PTD[playerid][1]);

		Unscrambler_PTD[playerid][2] = CreatePlayerTextDraw(playerid, 305.179687, 273.593383, "TO_UNSCRAMBLE_THE_WORD");
		PlayerTextDrawLetterSize(playerid, Unscrambler_PTD[playerid][2], 0.206330, 1.118813);
		PlayerTextDrawAlignment(playerid, Unscrambler_PTD[playerid][2], 1);
		PlayerTextDrawColor(playerid, Unscrambler_PTD[playerid][2], -2147483393);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][2], 0);
		PlayerTextDrawSetOutline(playerid, Unscrambler_PTD[playerid][2], 1);
		PlayerTextDrawBackgroundColor(playerid, Unscrambler_PTD[playerid][2], 255);
		PlayerTextDrawFont(playerid, Unscrambler_PTD[playerid][2], 2);
		PlayerTextDrawSetProportional(playerid, Unscrambler_PTD[playerid][2], 1);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][2], 0);
		PlayerTextDrawShow(playerid, Unscrambler_PTD[playerid][2]);

		Unscrambler_PTD[playerid][3] = CreatePlayerTextDraw(playerid, 141.369705, 285.194091, "scrambledword");
		PlayerTextDrawLetterSize(playerid, Unscrambler_PTD[playerid][3], 0.206330, 1.118813);
		PlayerTextDrawAlignment(playerid, Unscrambler_PTD[playerid][3], 1);
		PlayerTextDrawColor(playerid, Unscrambler_PTD[playerid][3], -1);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][3], 0);
		PlayerTextDrawSetOutline(playerid, Unscrambler_PTD[playerid][3], 1);
		PlayerTextDrawBackgroundColor(playerid, Unscrambler_PTD[playerid][3], 255);
		PlayerTextDrawFont(playerid, Unscrambler_PTD[playerid][3], 2);
		PlayerTextDrawSetProportional(playerid, Unscrambler_PTD[playerid][3], 1);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][3], 0);
		PlayerTextDrawShow(playerid, Unscrambler_PTD[playerid][3]);

		Unscrambler_PTD[playerid][4] = CreatePlayerTextDraw(playerid, 137.902801, 296.924377, "YOU_HAVE");
		PlayerTextDrawLetterSize(playerid, Unscrambler_PTD[playerid][4], 0.206330, 1.118813);
		PlayerTextDrawAlignment(playerid, Unscrambler_PTD[playerid][4], 1);
		PlayerTextDrawColor(playerid, Unscrambler_PTD[playerid][4], -2147483393);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][4], 0);
		PlayerTextDrawSetOutline(playerid, Unscrambler_PTD[playerid][4], 1);
		PlayerTextDrawBackgroundColor(playerid, Unscrambler_PTD[playerid][4], 255);
		PlayerTextDrawFont(playerid, Unscrambler_PTD[playerid][4], 2);
		PlayerTextDrawSetProportional(playerid, Unscrambler_PTD[playerid][4], 1);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][4], 0);
		PlayerTextDrawShow(playerid, Unscrambler_PTD[playerid][4]);

		Unscrambler_PTD[playerid][5] = CreatePlayerTextDraw(playerid, 184.539016, 297.024383, "001");
		PlayerTextDrawLetterSize(playerid, Unscrambler_PTD[playerid][5], 0.206330, 1.118813);
		PlayerTextDrawAlignment(playerid, Unscrambler_PTD[playerid][5], 1);
		PlayerTextDrawColor(playerid, Unscrambler_PTD[playerid][5], -1);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][5], 0);
		PlayerTextDrawSetOutline(playerid, Unscrambler_PTD[playerid][5], 1);
		PlayerTextDrawBackgroundColor(playerid, Unscrambler_PTD[playerid][5], 255);
		PlayerTextDrawFont(playerid, Unscrambler_PTD[playerid][5], 2);
		PlayerTextDrawSetProportional(playerid, Unscrambler_PTD[playerid][5], 1);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][5], 0);
		PlayerTextDrawShow(playerid, Unscrambler_PTD[playerid][5]);

		Unscrambler_PTD[playerid][6] = CreatePlayerTextDraw(playerid, 202.540191, 297.124389, "SECONDS_LEFT_TO_FINISh.");
		PlayerTextDrawLetterSize(playerid, Unscrambler_PTD[playerid][6], 0.206330, 1.118813);
		PlayerTextDrawAlignment(playerid, Unscrambler_PTD[playerid][6], 1);
		PlayerTextDrawColor(playerid, Unscrambler_PTD[playerid][6], -2147483393);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][6], 0);
		PlayerTextDrawSetOutline(playerid, Unscrambler_PTD[playerid][6], 1);
		PlayerTextDrawBackgroundColor(playerid, Unscrambler_PTD[playerid][6], 255);
		PlayerTextDrawFont(playerid, Unscrambler_PTD[playerid][6], 2);
		PlayerTextDrawSetProportional(playerid, Unscrambler_PTD[playerid][6], 1);
		PlayerTextDrawSetShadow(playerid, Unscrambler_PTD[playerid][6], 0);
		PlayerTextDrawShow(playerid, Unscrambler_PTD[playerid][6]);
	}
	else
	{
		PlayerTextDrawDestroy(playerid, Unscrambler_PTD[playerid][0]);
		PlayerTextDrawDestroy(playerid, Unscrambler_PTD[playerid][1]);
		PlayerTextDrawDestroy(playerid, Unscrambler_PTD[playerid][2]);
		PlayerTextDrawDestroy(playerid, Unscrambler_PTD[playerid][3]);
		PlayerTextDrawDestroy(playerid, Unscrambler_PTD[playerid][4]);
		PlayerTextDrawDestroy(playerid, Unscrambler_PTD[playerid][5]);
		PlayerTextDrawDestroy(playerid, Unscrambler_PTD[playerid][6]);
	}
	return 1;
}

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(newstate == PLAYER_STATE_DRIVER)
	{
		new vehicleid = GetPlayerVehicleID(playerid);
		
		if(!vehicleData[vehicleid][eVehicleEngineStatus] && !IsRentalVehicle(vehicleid))
			SendClientMessage(playerid, COLOR_DARKGREEN, "����ͧ¹��Ѻ���� (/engine)");
	
		if(vehicleData[vehicleid][eVehicleOwnerDBID] == playerData[playerid][pDBID])
			SendClientMessageEx(playerid, COLOR_WHITE, "�Թ�յ�͹�Ѻ��� %s �ͧ�س", ReturnVehicleName(vehicleid));

		new oldcar = gLastCar[playerid];
		if(oldcar != 0)
		{
			if((!vehicleData[oldcar][eVehicleDBID] && !vehicleData[oldcar][eVehicleAdminSpawn]) && !IsRentalVehicle(oldcar))
			{
				if(oldcar != vehicleid)
				{
					new
						engine,
						lights,
						alarm,
						doors,
						bonnet,
						boot,
						objective;
	
					GetVehicleParamsEx(oldcar, engine, lights, alarm, doors, bonnet, boot, objective);
					SetVehicleParamsEx(oldcar, engine, lights, alarm, 0, bonnet, boot, objective);
				}
			}
		}
		gLastCar[playerid] = vehicleid;
	}

	if (newstate == PLAYER_STATE_PASSENGER) {
		gPassengerCar[playerid] = GetPlayerVehicleID(playerid);
	}

	return 1;
}

CMD:engine(playerid, params[])
{
	if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
		return SendClientMessage(playerid, COLOR_LIGHTRED, "�س���������㹷���觤��Ѻ�ͧ�ҹ��˹�"); 
		
	new vehicleid = GetPlayerVehicleID(playerid);
	
	if(HasNoEngine(vehicleid))
		return SendClientMessage(playerid, COLOR_LIGHTRED, "�ҹ��˹Фѹ������������ͧ¹��"); 

	if(!vehicleData[vehicleid][eVehicleDBID] && !vehicleData[vehicleid][eVehicleAdminSpawn] && !IsRentalVehicle(vehicleid))
		return SendClientMessage(playerid, COLOR_LIGHTRED, "����觹������ö����੾���ҹ��˹���ǹ��� ��س������ҹ��˹��Ҹ�ó� (Static)");
		
	if(vehicleData[vehicleid][eVehicleFuel] <= 0.0 && !vehicleData[vehicleid][eVehicleAdminSpawn])
		return SendClientMessage(playerid, COLOR_LIGHTRED, "�ҹ��˹й�������������ԧ!"); 
	
	if(vehicleData[vehicleid][eVehicleFaction] > 0)
	{
		if(playerData[playerid][pFaction] != vehicleData[vehicleid][eVehicleFaction] && !playerData[playerid][pAdminDuty])
		{
			return SendClientMessage(playerid, COLOR_LIGHTRED, "�س����աح�����Ѻ�ҹ��˹Фѹ���"); 
		}
	}

	if(IsRentalVehicle(vehicleid) && !IsPlayerRentVehicle(playerid, vehicleid)) {
		return SendClientMessage(playerid, COLOR_LIGHTRED, "�س����աح�����Ѻ�ҹ��˹Фѹ���");
	}
	
	/*
	�ҹ��˹з������µç���ͧ (Hotwire)
	- �����ͧῤ���
	- �����ö�������Ңͧ
	- �����ö����աح����ͧ
	- ��������ʹ�Թ�ʡ���
	- �����ö���

	*/
	if(
	!vehicleData[vehicleid][eVehicleFaction] && 
	playerData[playerid][pDuplicateKey] != vehicleid && 
	vehicleData[vehicleid][eVehicleOwnerDBID] != playerData[playerid][pDBID] && 
	!vehicleData[vehicleid][eVehicleAdminSpawn] && 
	!IsRentalVehicle(vehicleid))
	{
		new idx, str[128];
		
		if(vehicleData[vehicleid][eVehicleEngineStatus] && !playerData[playerid][pAdminDuty])
			return GameTextForPlayer(playerid, "~g~ENGINE IS ALREADY ON", 3000, 3);
		
		playerData[playerid][pUnscrambling] = true;
	
		for(new i = 0; i < sizeof(UnscrambleWord); i++)
		{
			idx = random(sizeof(UnscrambleWord));
		}
		
		playerData[playerid][pUnscrambleID] = idx;
		
		switch(vehicleData[vehicleid][eVehicleImmobLevel])
		{
			case 1: playerData[playerid][pUnscramblerTime] = 125; 
			case 2: playerData[playerid][pUnscramblerTime] = 100; 
			case 3: playerData[playerid][pUnscramblerTime] = 75; 
			case 4: playerData[playerid][pUnscramblerTime] = 50;
			case 5: playerData[playerid][pUnscramblerTime] = 25;
		}
		
		playerData[playerid][pUnscrambleTimer] = repeat OnPlayerUnscramble(playerid);
		
		CreateUnscrambleTextdraw(playerid);

		format(str, sizeof(str), "%s", UnscrambleWord[idx]); 
		PlayerTextDrawSetString(playerid, Unscrambler_PTD[playerid][3], str);
		
		format(str, sizeof(str), "%d", playerData[playerid][pUnscramblerTime]);
		PlayerTextDrawSetString(playerid, Unscrambler_PTD[playerid][5], str);
	
		return 1; 
	}
	
	if(!vehicleData[vehicleid][eVehicleEngineStatus])
	{
		SendNearbyMessage(playerid, 20.0, COLOR_PURPLE, "* %s ʵ�������ͧ¹��ͧ %s", ReturnRealName(playerid), ReturnVehicleName(vehicleid)); 
		ToggleVehicleEngine(vehicleid, true); vehicleData[vehicleid][eVehicleEngineStatus] = true;
	}
	else
	{
		SendNearbyMessage(playerid, 20.0, COLOR_PURPLE, "* %s �Ѻ����ͧ¹��ͧ %s", ReturnRealName(playerid), ReturnVehicleName(vehicleid)); 
		ToggleVehicleEngine(vehicleid, false); vehicleData[vehicleid][eVehicleEngineStatus] = false;
	}
	return 1;
}

alias:unscramble("uns");
CMD:unscramble(playerid, params[])
{
	if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
		return SendClientMessage(playerid, COLOR_LIGHTRED, "�س�����Ѻ�ҹ��˹�");
		
	if(!playerData[playerid][pUnscrambling])
		return SendClientMessage(playerid, COLOR_LIGHTRED, "�س���������µç�ҹ��˹�");
	
	if(isnull(params)) return SendSyntaxMessage(playerid, "/(uns)cramble [�Ӷʹ����]");
	
	if(strequal(UnscrambleWord[playerData[playerid][pUnscrambleID]], params, true))
	{ // ��ҵͺ�١:
	
		playerData[playerid][pUnscrambleID] = random(sizeof(UnscrambleWord)); 
		
		new displayString[60], vehicleid = GetPlayerVehicleID(playerid);
		
		format(displayString, 60, "%s", ScrambleWord(UnscrambleWord[playerData[playerid][pUnscrambleID]]));
		PlayerTextDrawSetString(playerid, Unscrambler_PTD[playerid][3], displayString); 
		
		//���ҷ��������鹨Т������Ѻ����Ţͧ��͹���:
		playerData[playerid][pUnscramblerTime] += (7 - vehicleData[vehicleid][eVehicleImmobLevel]) * 2;
		playerData[playerid][pScrambleSuccess]++; 
		
		PlayerPlaySound(playerid, 1052, 0, 0, 0);
		//�е����µç������稹�� �������Ѻ�������͹���:
		if(playerData[playerid][pScrambleSuccess] >= (vehicleData[vehicleid][eVehicleImmobLevel] * 2) + 2)
		{
			stop playerData[playerid][pUnscrambleTimer];
			playerData[playerid][pScrambleSuccess] = 0; 
			playerData[playerid][pUnscrambling] = false;
			
			playerData[playerid][pUnscrambleID] = 0;
			playerData[playerid][pUnscramblerTime] = 0;
			
			playerData[playerid][pScrambleFailed] = 0;
			
			GameTextForPlayer(playerid, "~g~ENGINE TURNED ON", 2000, 3); 
			CreateUnscrambleTextdraw(playerid, false);
			
			SendNearbyMessage(playerid, 20.0, COLOR_PURPLE, "* %s ʵ�������ͧ¹��ͧ %s", ReturnRealName(playerid), ReturnVehicleName(vehicleid)); 
			ToggleVehicleEngine(vehicleid, true); vehicleData[vehicleid][eVehicleEngineStatus] = true;
		}	
	}
	else
	{
		PlayerPlaySound(playerid, 1055, 0, 0, 0); 
		
		playerData[playerid][pUnscrambleID] = random(sizeof(UnscrambleWord)); 
		
		new displayString[60];
		
		format(displayString, 60, "%s", ScrambleWord(UnscrambleWord[playerData[playerid][pUnscrambleID]]));
		PlayerTextDrawSetString(playerid, Unscrambler_PTD[playerid][3], displayString); 
		
		playerData[playerid][pScrambleFailed]++; 
		playerData[playerid][pUnscramblerTime] -= random(6)+1;
		
		if(playerData[playerid][pScrambleFailed] >= 5)
		{
			stop playerData[playerid][pUnscrambleTimer];
			playerData[playerid][pScrambleSuccess] = 0; 
			playerData[playerid][pUnscrambling] = false;
			
			playerData[playerid][pUnscrambleID] = 0;
			playerData[playerid][pUnscramblerTime] = 0;
			
			playerData[playerid][pScrambleFailed] = 0;
			
			new 
				vehicleid = GetPlayerVehicleID(playerid)
			;
			
			ToggleVehicleAlarms(vehicleid, true);
			NotifyVehicleOwner(vehicleid);
			
			ClearAnimations(playerid);
			CreateUnscrambleTextdraw(playerid, false);
		}
	}
	
	return 1;
}

hook OnVehicleSpawn(vehicleid)
{
	if(HasNoEngine(vehicleid))
		ToggleVehicleEngine(vehicleid, true);
	
	return 1;
}

timer OnPlayerUnscramble[1000](playerid)
{	
	if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
	{
		playerData[playerid][pUnscrambling] = false;
		playerData[playerid][pUnscramblerTime] = 0;
		playerData[playerid][pUnscrambleID] = 0;
		
		playerData[playerid][pScrambleSuccess] = 0; 
		playerData[playerid][pScrambleFailed] = 0; 
		stop playerData[playerid][pUnscrambleTimer];
		
		CreateUnscrambleTextdraw(playerid, false);
		return 1;
	}
	
	playerData[playerid][pUnscramblerTime]--;
	
	new timerString[20];
	
	format(timerString, 20, "%d", playerData[playerid][pUnscramblerTime]);
	PlayerTextDrawSetString(playerid, Unscrambler_PTD[playerid][5], timerString);
	
	if(playerData[playerid][pUnscramblerTime] < 1)
	{
		playerData[playerid][pUnscrambling] = false;
		playerData[playerid][pUnscramblerTime] = 0;
		playerData[playerid][pUnscrambleID] = 0;
		
		playerData[playerid][pScrambleSuccess] = 0; 
		playerData[playerid][pScrambleFailed] = 0; 
		stop playerData[playerid][pUnscrambleTimer]; 
		
		CreateUnscrambleTextdraw(playerid, false);
		
		new 
			vehicleid = GetPlayerVehicleID(playerid)
		;
			
		ToggleVehicleAlarms(vehicleid, true);
		NotifyVehicleOwner(vehicleid);
		
		ClearAnimations(playerid);
	}
	return 1;
}

timer OnVehicleAlarm[5000](vehicleid)
{
	return ToggleVehicleAlarms(vehicleid, false);
}

stock NotifyVehicleOwner(vehicleid)
{
	new playerid = INVALID_PLAYER_ID;

	foreach(new i : Player)
	{
		if(playerData[i][pDBID] == vehicleData[vehicleid][eVehicleOwnerDBID])
		{
			return SendClientMessage(playerid, COLOR_YELLOW2, "SMS: �ѭ�ҳ��͹����ҹ��˹Тͧ�س�ѧ���, �����: �ѭ�ҳ��͹��¢ͧ�ҹ��˹� (����Һ)");
		}
	}
	return 0;
}