IncludeScript( "bet_shared.nut" );

COLOR_WHITE <- TextColorBlend( 228, 228, 228, 150, 150, 150 );
COLOR_WHITE_NOBLEND <- TextColor( 228, 228, 228 );
COLOR_GRAY <- TextColor( 160, 160, 160 );
COLOR_GREEN <- TextColor( 78, 165, 65 );
COLOR_GREENISH <- TextColor( 155, 208, 74 );
COLOR_LIGHTGREEN <- TextColor( 70, 213, 145 );
COLOR_BLUE <- TextColor( 69, 135, 184 );
COLOR_LIGHTRED <- TextColor( 242, 105, 105 );
COLOR_RED <- TextColor( 219, 64, 64 );
COLOR_REDER <- TextColor( 230, 16, 16 );
COLOR_NICKNAMES <- TextColorBlend( 210, 84, 62, 189, 83, 83 ); 

// basically reduce points gain by how many times on each difficulty
PointGainChancePerDifficulty_t <- [ 10.0, 7.0, 3.0, 1.5, 1.0 ];

AlienWorth_t <- 
{
	asw_drone = 1
	asw_drone_jumper = 1
	asw_drone_uber = 5
	asw_buzzer = 1
	asw_shaman = 3
	asw_harvester = 5
	asw_shieldbug = 10
	asw_boomer = 7
	asw_mortarbug = 5
	asw_ranger = 2
	asw_parasite_defanged = 1
	asw_parasite = 2
	
	npc_headcrab = 1
	npc_headcrab_black = 1
	npc_headcrab_fast = 1
	npc_headcrab_poison = 1
	npc_antlion = 1
	npc_antlion_worker = 1
	npc_antlionguard = 10
	npc_antlionguard_normal = 10
	npc_antlionguard_cavern = 10
	npc_zombie = 1
	npc_zombie_torso = 1
	npc_fastzombie = 1
	npc_fastzombie_torso = 1
	npc_poisonzombie = 1
};

const PROFILE_VERSION = 1;
const BET_PLACE_TIME = 30.0;

Bet_t <- [ {}, {} ];
PointsChanged_t <- {};
SenderLevels_t <- {};
HealStat_t <- {};
hThinkerAlienIndentifier <- null;
hThinkerHealing <- null;
hThinkerHudUpdater <- null;
bMissionStarted <- false;
fMissionStartTime <- 0.0;

function OnGameplayStart()
{	
	bMissionStarted <- true;
	fMissionStartTime <- Time();
	
	DoEntFire( "worldspawn", "runscriptcode", "BetTimeExpired()", BET_PLACE_TIME, null, null );
	
	if ( !RandomInt( 0, 9 ) )
		ClientPrint( null, 3, COLOR_WHITE_NOBLEND + "BET MOD: " + COLOR_BLUE + "You can start a bet on who will win this round, swarm or marines. More info with " + COLOR_WHITE_NOBLEND + "/bet info" );
	
	local hMarine = null;
	while ( hMarine = Entities.FindByClassname( hMarine, "asw_marine" ) )
		InitHud( hMarine );
	
	hThinkerAlienIndentifier <- AddThinkToEnt_Fast( "worldspawn", "Thinker_AlienIdentifier", 0.2 );
	hThinkerHealing <- AddThinkToEnt_Fast( "worldspawn", "Thinker_Healing", 0.2 );
	hThinkerHudUpdater <- AddThinkToEnt_Fast( "worldspawn", "Thinker_HudUpdater", 0.2 );
}

function InitHud( hMarine )
{
	if ( !hMarine.IsInhabited() )
		return;
	
	local hPlayer = hMarine.GetCommander();
	if ( !hPlayer )
		return;
	
	local hHud = Entities.CreateByClassname( "rd_hud_vscript" );
	hHud.__KeyValueFromString( "client_vscript", "rd_hudscript_text.nut" );
	hHud.Spawn();
	hHud.Activate();
	hHud.SetEntity( 0, hMarine );
	hHud.SetInt( 63, 1 );
	hHud.SetName( "bethud_" + GetNetworkID( hPlayer ) );

	local strFileName = "bet_profile_" + GetNetworkID( hPlayer );
	local Profile_t = FileToProfile( strFileName );
	if ( Profile_t.len() == 0 )
	{
		local strNew = PROFILE_VERSION + "|0";
		StringToFile( strFileName, strNew );
		
		Profile_t = StringToProfile( strNew );
	}
	else if ( Profile_t[0].tointeger() != PROFILE_VERSION )
	{
		// future code here
	}

	local nCurPts = Profile_t[1].tointeger();
	local nCurLvl = PointsToLevel( nCurPts );
	local nNxtPts = LevelToPoints( nCurLvl );
	
	hHud.SetString( 0, "LEVEL: " + nCurLvl.tostring() + "|POINTS: " + nCurPts.tostring() + "/" + nNxtPts.tostring() + "|RANK: " + LevelToRank( nCurLvl ) );
	
	// LEVEL string
	hHud.SetFloat( 0, 0.8 );	// ScreenPosX
	hHud.SetFloat( 1, 0.05 );	// ScreenPosY
	hHud.SetInt( 0, 200 );	// r
	hHud.SetInt( 1, 10 );	// g
	hHud.SetInt( 2, 10 );	// b
	hHud.SetInt( 3, 192 );	// a
	hHud.SetInt( 4, 12 );	// font DefaultLarge
	
	// POINTS string
	hHud.SetFloat( 2, 0.8 );	// ScreenPosX
	hHud.SetFloat( 3, 0.075 );	// ScreenPosY
	hHud.SetInt( 5, 150 );	// r
	hHud.SetInt( 6, 20 );	// g
	hHud.SetInt( 7, 30 );	// b
	hHud.SetInt( 8, 192 );	// a
	hHud.SetInt( 9, 12 );	// font DefaultLarge
	
	// RANK string
	local vecRankColor = LevelToColor( nCurLvl );
	hHud.SetFloat( 4, 0.8 );	// ScreenPosX
	hHud.SetFloat( 5, 0.1 );	// ScreenPosY
	hHud.SetInt( 10, vecRankColor.x );	// r
	hHud.SetInt( 11, vecRankColor.y );	// g
	hHud.SetInt( 12, vecRankColor.z );	// b
	hHud.SetInt( 13, 192 );	// a
	hHud.SetInt( 14, 12 );	// font DefaultLarge
	
	// 0 - lvl, 1 - pts, 2 - pts for rankup, 3 - name, 4 - pts at start, 5 - minus pts for ff, 6 - placement in top100
	PointsChanged_t[ GetNetworkID( hPlayer ) ] <- [ nCurLvl, nCurPts, nNxtPts, hPlayer.GetPlayerName(), nCurPts, 0, 0 ];
	
	HealStat_t[ GetNetworkID( hPlayer ) ] <- 0;
	
	return hHud;
}

function AwardPoints( hMarine, nPoints )
{
	local hPlayer = hMarine.GetCommander();
	if ( !hPlayer )
		return;
	
	local hHud = Entities.FindByName( null, "bethud_" + GetNetworkID( hPlayer ) );
	if ( !hHud )
		hHud = InitHud( hMarine );
	
	if ( !( GetNetworkID( hPlayer ) in PointsChanged_t ) )
		return;
	
	if ( nPoints == 0 )
		return;
	
	// chance to not award points on easier difficulties
	if ( nPoints > 0 && RandomFloat( 0.0, PointGainChancePerDifficulty_t[ Convars.GetFloat( "asw_skill" ).tointeger() - 1 ] ) > 1.0 )
		return;
	
	if ( nPoints < 0 )
		PointsChanged_t[ GetNetworkID( hPlayer ) ][5] -= nPoints;
	
	PointsChanged_t[ GetNetworkID( hPlayer ) ][1] += nPoints;
	if ( PointsChanged_t[ GetNetworkID( hPlayer ) ][1] < 0 )
		PointsChanged_t[ GetNetworkID( hPlayer ) ][1] = 0;
	
	local nCurLvl = PointsChanged_t[ GetNetworkID( hPlayer ) ][0];
	local nCurPts = PointsChanged_t[ GetNetworkID( hPlayer ) ][1];
	local nNxtPts = PointsChanged_t[ GetNetworkID( hPlayer ) ][2];
	
	if ( nCurPts >= nNxtPts )
	{
		nCurLvl = ++PointsChanged_t[ GetNetworkID( hPlayer ) ][0];
		
		PointsChanged_t[ GetNetworkID( hPlayer ) ][2] = LevelToPoints( nCurLvl );
		nNxtPts = PointsChanged_t[ GetNetworkID( hPlayer ) ][2];
		
		// RANK string
		local vecRankColor = LevelToColor( nCurLvl );
		hHud.SetInt( 10, vecRankColor.x );	// r
		hHud.SetInt( 11, vecRankColor.y );	// g
		hHud.SetInt( 12, vecRankColor.z );	// b
	}

	hHud.SetString( 0, "LEVEL: " + nCurLvl.tostring() + "|POINTS: " + nCurPts.tostring() + "/" + nNxtPts.tostring() + "|RANK: " + LevelToRank( nCurLvl ) );
}

function AlienDied( hAlien, hMarine )
{
	if ( !hMarine || !hMarine.IsValid() || hMarine.GetClassname() != "asw_marine" || !hMarine.IsInhabited() )
		return;

	if ( !hAlien || !hAlien.IsValid() )
		return;

	local strAlien = hAlien.GetClassname();
	if ( !( strAlien in AlienWorth_t ) )
		return;
	
	AwardPoints( hMarine, AlienWorth_t[ strAlien ] );
}

function WriteAwardedPoints()
{
	foreach( strSteamID, Data_t in PointsChanged_t )
	{
		ClientPrint( null, 3, "%s1%s2 %s3pts %s1" + Data_t[4].tostring() + "%s3 → %s1" + Data_t[1].tostring() + "%s3 (%s1%s4%s3). %s1-" + Data_t[5] + " %s3for FF. " + ( Data_t[6] ? "Rank %s1#" + Data_t[6].tostring() + "%s3." : "" ), COLOR_WHITE, Data_t[3], COLOR_GREEN, ( Data_t[1] - Data_t[4] ) >= 0 ? "+" + ( Data_t[1] - Data_t[4] ).tostring() : ( Data_t[1] - Data_t[4] ).tostring() );
		
		local strData = PROFILE_VERSION.tostring() + "|" + Data_t[1].tostring();
		
		StringToFile( "bet_profile_" + strSteamID, strData );
	}
}

function OnTakeDamage_Alive_Any( victim, inflictor, attacker, weapon, damage, damageType, ammoName )
{	
	if ( victim == null || attacker == null )
		return damage;
	
	// reward stunning aliens with tesla
	if ( attacker.GetClassname() == "asw_marine" && attacker.IsInhabited() && victim.IsAlien() && weapon && weapon.GetClassname() == "asw_weapon_tesla_gun" )
	{
		if ( RandomInt( 0, 3 ) )
			return damage;
			
		AwardPoints( attacker, 1 );
		
		return damage;
	}
	
	if ( attacker.GetClassname() != "asw_marine" || victim.GetClassname() != "asw_marine" )
		return damage;
		
	if ( !attacker.IsInhabited() || !victim.IsInhabited() )
		return damage;
	
	// dont punish ff from gas, firemine, lasermine
	if ( weapon && ( weapon.GetClassname() == "asw_gas_grenade_projectile" || weapon.GetClassname() == "asw_weapon_mines" || weapon.GetClassname() == "asw_weapon_laser_mines" ) )
		return damage;
	
	// dont punish ff to infested marines
	if ( NetProps.GetPropBool( NetProps.GetPropEntity( victim, "m_MarineResource" ), "m_bInfested" ) )
		return damage;
	
	if ( victim == attacker )
	{	
		local nHealth = victim.GetHealth();
		local nFF = damage.tointeger();
		if ( nFF > nHealth )
			nFF = nHealth;
			
		AwardPoints( attacker, -nFF / 4 );
	}
	else
	{
		local nHealth = victim.GetHealth();
		local nFF = damage.tointeger();
		if ( nFF > nHealth )
			nFF = nHealth;
			
		AwardPoints( attacker, -nFF / 2 );
	}
	
	return damage;
}

function OnReceivedTextMessage( hRecipient, hSender, strMessage )
{
	strMessage = strMessage.slice( 0, strMessage.len() - 1 );
	
	local strSenderName = hSender.GetPlayerName();
	local strText = strMessage.slice( strSenderName.len() + 2 );
	
	// treat '!', '&' etc. as a '/'
	if ( strText.len() > 1 )
	{
		local strPref = strText.slice( 0, 1 );
		
		switch ( strPref )
		{
			case "!":
			case (92).tochar():		// "\", doesnt parse
			case "&":
			case "?":
			{
				strText = "/" + strText.slice( 1 );
			}
		}
	}
	
	local argv = split( strText, " " );
	
	if ( argv.len() && argv[0] == "/bet" )
		return;
	
	local nSenderLvl = 1;
	local strSenderID = GetNetworkID( hSender );
	if ( strSenderID in PointsChanged_t )
	{
		nSenderLvl = PointsChanged_t[ strSenderID ][0];
	}
	else if ( strSenderID in SenderLevels_t )
	{
		nSenderLvl = SenderLevels_t[ strSenderID ];
	}
	else
	{
		local Profile_t = FileToProfile( "bet_profile_" + strSenderID );
		if ( Profile_t.len() )
			nSenderLvl = PointsToLevel( Profile_t[1].tointeger() );
		
		SenderLevels_t[ strSenderID ] <- nSenderLvl;
	}
	
	local vecLvlColor = LevelToColor( nSenderLvl );
	strMessage = COLOR_GRAY + "[" + TextColor( vecLvlColor.x, vecLvlColor.y, vecLvlColor.z ) + "LVL " + nSenderLvl.tostring() + COLOR_GRAY + "] " + COLOR_NICKNAMES + strSenderName + COLOR_WHITE_NOBLEND + strMessage.slice( strSenderName.len() );
	
	return strMessage;
}

function OnGameEvent_player_say( params )
{
	if ( !GetPlayerFromUserID( params["userid"] ) )
		return;
	
	local hCaller = GetPlayerFromUserID( params["userid"] );
	if ( !hCaller )
		return;
	
	local text = params["text"].tolower();
	
	// treat '!', '&' etc. as a '/'
	if ( text.len() > 1 )
	{
		local strPref = text.slice( 0, 1 );
		
		switch ( strPref )
		{
			case "!":
			case (92).tochar():		// "\", doesnt parse
			case "&":
			case "?":
			{
				text = "/" + text.slice( 1 );
			}
		}
	}
	
	local argv = split( text, " " );
	local argc = argv.len();
	
	if ( text == "/bet info" )
	{
		local Profile_t = FileToProfile( "bet_profile_" + GetNetworkID( hCaller ) );
		local strPoints = "0";
		if ( Profile_t.len() )
			strPoints = Profile_t[1].tointeger().tostring();
		
		ClientPrint( hCaller, 3, "%s1You have: %s2%s3%s1 pts.", COLOR_RED, COLOR_WHITE_NOBLEND, strPoints );
		ClientPrint( hCaller, 3, "%s1Do %s2/bet marines <amount>%s1 to bet for marines.", COLOR_BLUE, COLOR_WHITE_NOBLEND );
		ClientPrint( hCaller, 3, "%s1Do %s2/bet swarm <amount>%s1 to bet for swarm.", COLOR_BLUE, COLOR_WHITE_NOBLEND );
		ClientPrint( hCaller, 3, "%s2<amount>%s1 can be a %s2value%s1, a %s2percentage%s1 or %s2all%s1.", COLOR_BLUE, COLOR_WHITE_NOBLEND );
		ClientPrint( hCaller, 3, "%s1You are placing bets with other players, betting alone does not do anything.", COLOR_BLUE );
		ClientPrint( hCaller, 3, "%s1Minimal bet is 100 points.", COLOR_BLUE );
		ClientPrint( hCaller, 3, "%s1You can not place bets if you are taking part in the round and you can only place bets in first %s2 seconds of the mission.", COLOR_RED, BET_PLACE_TIME );
		ClientPrint( hCaller, 3, "%s1Do %s2/top %s2<number>%s1 to see players with top number of points.", COLOR_BLUE, COLOR_WHITE_NOBLEND );
		ClientPrint( hCaller, 3, "%s1Link to mod: %s2https://github.com/jhh8/rd-betting-mod", COLOR_BLUE, COLOR_WHITE_NOBLEND );
		
		return;
	}
	
	if ( argc == 2 && argv[0] == "/top" )
	{
		local nTop = 10;
		
		try
		{
			nTop = argv[1].tointeger();
		}
		catch ( exc ) {}
		
		local Placements_t = split( FileToString( "bet_top100" ), "|" );
		for ( local i = 0; i < Placements_t.len(); i++ )
			Placements_t[i] = strip( Placements_t[i] );
			
		for ( local i = 0; i < Placements_t.len() && i < nTop; i++ )
			ClientPrint( hCaller, 3, "%s1" + ( i + 1 ).tostring() + ". %s2%s3%s1 - %s2%s4%s1 pts.", COLOR_GREEN, COLOR_WHITE, Placements_t[ i * 3 + 1 ], Placements_t[ i * 3 + 2 ] );
			
		return;
	}
	
	if ( argc == 3 && argv[0] == "/bet" )
	{
		if ( !bMissionStarted )
		{
			ClientPrint( hCaller, 3, "%s1You can only bet after mission has started.", COLOR_RED );
			return;
		}
		
		if ( GetNetworkID( hCaller ) in PointsChanged_t )
		{
			ClientPrint( hCaller, 3, "%s1You can not bet if you have played this round.", COLOR_RED );
			return;
		}
		
		if ( Time() - fMissionStartTime > BET_PLACE_TIME )
		{
			ClientPrint( hCaller, 3, "%s1You can not place bets more than %s2 seconds into the mission.", COLOR_RED, BET_PLACE_TIME );
			return;
		}
		
		if ( argv[1] == "marines" || argv[1] == "swarm" )
		{
			local strID = GetNetworkID( hCaller );
			local Profile_t = FileToProfile( "bet_profile_" + GetNetworkID( hCaller ) );
			local nPoints = 0;
			if ( Profile_t.len() )
				nPoints = Profile_t[1].tointeger();
				
			if ( strID in Bet_t[0] )
				nPoints -= Bet_t[0][ strID ];
				
			if ( strID in Bet_t[1] )
				nPoints -= Bet_t[1][ strID ];
			
			if ( nPoints < 100 )
			{
				ClientPrint( hCaller, 3, "%s1You don't have enough points to bet. Minimal bet is 100 points.", COLOR_RED );
				return;
			}
			
			local nBet = -1;
			if ( argv[2] == "all" )
			{
				nBet = nPoints;
			}
			else if ( argv[2].find( "%" ) )
			{
				try
				{
					nBet = argv[2].slice( 0, argv[2].find( "%" ) ).tofloat() * 0.01 * nPoints;
					nBet = nBet.tointeger();
				}
				catch ( exc )
				{
					ClientPrint( hCaller, 3, "%s1Invalid bet amount.", COLOR_RED );
					return;
				}
			}
			else
			{
				try
				{
					nBet = argv[2].tointeger();
				}
				catch ( exc )
				{
					ClientPrint( hCaller, 3, "%s1Invalid bet amount.", COLOR_RED );
					return;
				}
			}
			
			if ( nBet < 100 )
			{
				ClientPrint( hCaller, 3, "%s1Minimal bet is 100 points. Your bet amount is %s2%s3%s1 points.", COLOR_RED, COLOR_REDER, nBet.tostring() );
				return;
			}
			
			if ( nBet > nPoints )
			{
				ClientPrint( hCaller, 3, "%s1Bet amount higher than owned points.", COLOR_RED );
				return;
			}
			
			local nFactionID = 0;
			if ( argv[1] == "swarm" )
				nFactionID = 1;
			
			if ( strID in Bet_t[ ( !nFactionID ).tointeger() ] )
			{
				ClientPrint( hCaller, 3, "%s1You can not bet against marines and swarm at same time!", COLOR_RED );
				return;
			}
			
			PlaceBet( strID, nBet, nFactionID );
		}
	}
}

function PlaceBet( strID, nAmount, nFactionID )
{
	ClientPrint( null, 3, "%s1Someone has placed a bet of %s2%s3%s1 on %s2%s4%s1!", COLOR_GREENISH, COLOR_WHITE, nAmount.tostring(), nFactionID ? "swarm" : "marines" );
	
	if ( !( strID in Bet_t[ nFactionID ] ) )
		Bet_t[ nFactionID ][ strID ] <- nAmount;
	else
		Bet_t[ nFactionID ][ strID ] += nAmount;
	
	local nMarinesAmount = 0;
	foreach( strID, nTotalAmount in Bet_t[0] )
		nMarinesAmount += nTotalAmount;
		
	local nSwarmAmount = 0;
	foreach( strID, nTotalAmount in Bet_t[1] )
		nSwarmAmount += nTotalAmount;
	
	ClientPrint( null, 3, "%s1marines %s2%s3%s1 - %s2%s4%s1 swarm", COLOR_GREEN, COLOR_WHITE, nMarinesAmount, nSwarmAmount );
	
	if ( nMarinesAmount > 0 && nSwarmAmount > 0 )
	{
		local fMarinesCoeff = 1.0 * ( nSwarmAmount + nMarinesAmount ) / nMarinesAmount;
		local fSwarmCoeff = 1.0 * ( nSwarmAmount + nMarinesAmount ) / nSwarmAmount;
		
		ClientPrint( null, 3, "%s1coeff: %s2%s3%s1 - %s2%s4", COLOR_GREEN, COLOR_WHITE, TruncateFloat( fMarinesCoeff, 2 ), TruncateFloat( fSwarmCoeff, 2 ) );
	}
	
	local hPlayer = null;
	while ( hPlayer = Entities.FindByClassname( hPlayer, "player" ) )
	{
		local _strID = GetNetworkID( hPlayer );
		
		if ( _strID in Bet_t[0] || _strID in Bet_t[1] )
			ClientPrint( hPlayer, 3, "%s1Your bet: %s2%s3%s1 on %s2%s4%s1.\n", COLOR_GREENISH, COLOR_WHITE, _strID in Bet_t[0] ? Bet_t[0][ _strID ] : Bet_t[1][ _strID ], _strID in Bet_t[0] ? "marines" : "swarm" );
		else
			ClientPrint( hPlayer, 3, "%s1Betting info: %s2/bet info\n", COLOR_GREENISH, COLOR_WHITE );
	}
}

function BetTimeExpired()
{
	if ( !Bet_t[0].len() && !Bet_t[1].len() )
		return;
		
	if ( !Bet_t[0].len() || !Bet_t[1].len() )
	{
		::Bet_t <- [ {}, {} ];
		ClientPrint( null, 3, "%s1Bet failed! One sided bet.", COLOR_RED );
	}
}

function EndBet( nFactionWon )
{
	if ( !Bet_t[0].len() || !Bet_t[1].len() )
		return;
	
	foreach( strID, Data_t in PointsChanged_t )
	{
		local strParticipant = NetworkIDToName( strID );
		
		foreach( _strID, nBetAmount in Bet_t[0] )
		{
			if ( _strID == strID && nFactionWon == 0 )
			{
				ClientPrint( null, 3, "%s1Bet failed! %s2%s3%s1 has participated in gameplay with a placed bet. Rigged!", COLOR_RED, COLOR_WHITE_NOBLEND, strParticipant ? strParticipant : "network id " + strID );
				return;
			}
		}
		
		foreach( _strID, nBetAmount in Bet_t[1] )
		{
			if ( _strID == strID && nFactionWon == 1 )
			{
				ClientPrint( null, 3, "%s1Bet failed! %s2%s3%s1 has participated in gameplay with a placed bet. Rigged!", COLOR_RED, COLOR_WHITE_NOBLEND, strParticipant ? strParticipant : "id " + strID );
				return;
			}
		}
	}
	
	ClientPrint( null, 3, "%s1%s3%s2 wins the bet!", COLOR_WHITE_NOBLEND, COLOR_GREENISH, nFactionWon ? "swarm" : "marines" );
	
	local nMarinesAmount = 0;
	foreach( strID, nTotalAmount in Bet_t[0] )
		nMarinesAmount += nTotalAmount;
		
	local nSwarmAmount = 0;
	foreach( strID, nTotalAmount in Bet_t[1] )
		nSwarmAmount += nTotalAmount;
	
	local fMarinesCoeff = 1.0 * ( nSwarmAmount + nMarinesAmount ) / nMarinesAmount;
	local fSwarmCoeff = 1.0 * ( nSwarmAmount + nMarinesAmount ) / nSwarmAmount;
	
	if ( !nFactionWon )
	{
		foreach( strID, nBetAmount in Bet_t[0] )
		{
			local Profile_t = FileToProfile( "bet_profile_" + strID );
			if ( !Profile_t.len() )
				continue;
			
			local nPoints = Profile_t[1].tointeger();
			local nNewPoints = nPoints + ( 1.0 * nBetAmount * fMarinesCoeff ).tointeger() - nBetAmount;
			local strName = NetworkIDToName( strID );
			
			ClientPrint( null, 3, "%s2%s3%s1 has won %s2%s4%s1 points! %s2" + nPoints.tostring() + "%s1 → %s2" + nNewPoints.tostring() + "%s1.", COLOR_LIGHTGREEN, COLOR_WHITE, strName ? strName : "id " + strID, nNewPoints - nPoints );
			
			StringToFile( "bet_profile_" + strID, PROFILE_VERSION + "|" + nNewPoints.tostring() );
		}
		
		foreach( strID, nBetAmount in Bet_t[1] )
		{
			local Profile_t = FileToProfile( "bet_profile_" + strID );
			if ( !Profile_t.len() )
				continue;
			
			local nPoints = Profile_t[1].tointeger();
			local nNewPoints = nPoints - nBetAmount;
			local strName = NetworkIDToName( strID );
			
			ClientPrint( null, 3, "%s2%s3%s1 has lost %s2%s4%s1 points! %s2" + nPoints.tostring() + "%s1 → %s2" + nNewPoints.tostring() + "%s1.", COLOR_LIGHTRED, COLOR_WHITE, strName ? strName : "id " + strID, nNewPoints - nPoints );
			
			StringToFile( "bet_profile_" + strID, PROFILE_VERSION + "|" + nNewPoints.tostring() );
		}
	}
	else
	{	
		foreach( strID, nBetAmount in Bet_t[1] )
		{
			local Profile_t = FileToProfile( "bet_profile_" + strID );
			if ( !Profile_t.len() )
				continue;
			
			local nPoints = Profile_t[1].tointeger();
			local nNewPoints = nPoints + ( 1.0 * nBetAmount * fSwarmCoeff ).tointeger() - nBetAmount;
			local strName = NetworkIDToName( strID );
			
			ClientPrint( null, 3, "%s2%s3%s1 has won %s2%s4%s1 points! %s2" + nPoints.tostring() + "%s1 → %s2" + nNewPoints.tostring() + "%s1.", COLOR_LIGHTGREEN, COLOR_WHITE, strName ? strName : "id " + strID, nNewPoints - nPoints );
			
			StringToFile( "bet_profile_" + strID, PROFILE_VERSION + "|" + nNewPoints.tostring() );
		}
		
		foreach( strID, nBetAmount in Bet_t[0] )
		{
			local Profile_t = FileToProfile( "bet_profile_" + strID );
			if ( !Profile_t.len() )
				continue;
			
			local nPoints = Profile_t[1].tointeger();
			local nNewPoints = nPoints - nBetAmount;
			local strName = NetworkIDToName( strID );
			
			ClientPrint( null, 3, "%s2%s3%s1 has lost %s2%s4%s1 points! %s2" + nPoints.tostring() + "%s1 → %s2" + nNewPoints.tostring() + "%s1.", COLOR_LIGHTRED, COLOR_WHITE, strName ? strName : "id " + strID, nNewPoints - nPoints );
			
			StringToFile( "bet_profile_" + strID, PROFILE_VERSION + "|" + nNewPoints.tostring() );
		}
	}
}

function ComputePlacements()
{
	local Placements_t = split( FileToString( "bet_top100" ), "|" );
	for ( local i = 0; i < Placements_t.len(); i++ )
		Placements_t[i] = strip( Placements_t[i] );
	
	if ( !Placements_t.len() )
		Placements_t = [ "0", "nosferatu", "-1" ];

	foreach ( strID, Data_t in PointsChanged_t )
	{
		local nPlacements = Placements_t.len() / 3;
		
		for ( local i = 0; i < nPlacements; i++ )
		{
			if ( strID == Placements_t[ i * 3 ] )
			{
				Placements_t.remove( i * 3 );
				Placements_t.remove( i * 3 );
				Placements_t.remove( i * 3 );
				
				break;
			}
		}
	}
	
	foreach ( strID, Data_t in PointsChanged_t )
	{
		local nPlacements = Placements_t.len() / 3;
		local nPoints = Data_t[1].tointeger();
		
		for ( local i = 0; i < nPlacements; i++ )
		{
			local _nPoints = Placements_t[ i * 3 + 2 ].tointeger();
			
			if ( nPoints > _nPoints )
			{
				Placements_t.insert( i * 3, nPoints.tostring() );
				Placements_t.insert( i * 3, FilterName( Data_t[3] ) );
				Placements_t.insert( i * 3, strID );
				
				break;
			}
		}
	}
	
	foreach ( strID, Data_t in PointsChanged_t )
	{
		local nPlacements = Placements_t.len() / 3;
		
		for ( local i = 0; i < nPlacements && i < 100; i++ )
		{
			if ( strID == Placements_t[ i * 3 ] )
			{
				PointsChanged_t[ strID ][6] = i + 1;
				
				break;
			}
		}
	}
	
	local strPlacements = "";
	local i = 0;
	while( 1 )
	{
		strPlacements += Placements_t[i] + "|" + Placements_t[i+1] + "|" + Placements_t[i+2];
		
		i += 3;
		
		if ( i >= Placements_t.len() || i >= 300 )
			break;
			
		strPlacements += "|\n";
	}
		
	StringToFile( "bet_top100", strPlacements );
}

function Event_Healed( hMarineHealer, nHealth )
{
	if ( nHealth < 5 )
		return;
	
	AwardPoints( hMarineHealer, 1 );
}

function Event_MissionEnd( bMissionFail )
{
	bMissionStarted <- false;
	
	ComputePlacements();
	WriteAwardedPoints();
	
	if ( hThinkerAlienIndentifier && hThinkerAlienIndentifier.IsValid() )
		hThinkerAlienIndentifier.Destroy();
		
	if ( hThinkerHealing && hThinkerHealing.IsValid() )
		hThinkerHealing.Destroy();
		
	if ( hThinkerHudUpdater && hThinkerHudUpdater.IsValid() )
		hThinkerHudUpdater.Destroy();
		
	EndBet( bMissionFail.tointeger() );
}

function OnGameEvent_mission_success( params )
{
	Event_MissionEnd( false );
}

function OnGameEvent_mission_failed( params )
{
	Event_MissionEnd( true );
}

function OnGameEvent_asw_mission_restart( params )
{
	PointsChanged_t <- {};
	HealStat_t <- {};
	SenderLevels_t <- {};
	Bet_t <- [ {}, {} ];
	bMissionStarted <- false;
	fMissionStartTime <- 0.0;
}

// remove '|' symbols from player's name
function FilterName( strName )
{
    local Split_t = split( strName, "|" );
	if ( Split_t.len() < 2 )
		return strName;
	
    local strFiltered = "";

    for ( local i = 0; i < Split_t.len(); ++i )
        strFiltered += Split_t[i];

    return strFiltered == "" ? "weird_name_person" : strFiltered;
}

function NetworkIDToName( strID )
{
	local hPlayer = null;
	while ( hPlayer = Entities.FindByClassname( hPlayer, "player" ) )
		if ( GetNetworkID( hPlayer ) == strID )
			return hPlayer.GetPlayerName();
	
	return null;
}

function GetNetworkID( hPlayer )
{
	return hPlayer.GetNetworkIDString().slice(10);
}

function FileToProfile( strFileName )
{
	local str = FileToString( strFileName );
	local arr = split( str, "|" );
	return arr;
}

function StringToProfile( strData )
{
	local arr = split( strData, "|" );
	return arr;
}

function TruncateFloat( value, precision )
{
	if ( precision < 0 || precision > 5 || typeof( value ) != "float" )	// sanity check
		return value;
	
	return ( value * pow( 10, precision ) ).tointeger().tofloat() / pow( 10, precision );
}

function AddThinkToEnt_Fast( strEnt, strFunction, fThinkSpeed )
{
	local hTimer = Entities.CreateByClassname( "logic_timer" );
	hTimer.__KeyValueFromFloat( "RefireTime", fThinkSpeed );
	EntityOutputs.AddOutput( hTimer, "OnTimer", strEnt, "RunScriptCode", "if ( self && self.IsValid() ) { " + strFunction + "() }", 0.0, -1 );

	hTimer.Spawn();
	hTimer.Activate();

	return hTimer;
}

function Thinker_Healing()
{
	local hMarine = null;
	while ( hMarine = Entities.FindByClassname( hMarine, "asw_marine" ) )
	{
		if ( !hMarine.IsInhabited() )
			continue;
		
		local hPlayer = hMarine.GetCommander();
		if ( !( GetNetworkID( hPlayer ) in HealStat_t ) )
			continue;
		
		local nHealthHealed = NetProps.GetPropInt( NetProps.GetPropEntity( hMarine, "m_MarineResource" ), "m_iMedicHealing" );
		if ( nHealthHealed > HealStat_t[ GetNetworkID( hPlayer ) ] )
		{
			Event_Healed( hMarine, nHealthHealed - HealStat_t[ GetNetworkID( hPlayer ) ] )
			
			HealStat_t[ GetNetworkID( hPlayer ) ] <- nHealthHealed;
		}
	}
}

function Thinker_HudUpdater()
{
	// make sure every player which is playing right now has a hud
	local hPlayer = null;
	while ( hPlayer = Entities.FindByClassname( hPlayer, "player" ) )
	{
		local strID = GetNetworkID( hPlayer );
		local hHud = Entities.FindByName( null, "bethud_" + strID );
		local hMarine = hPlayer.GetMarine();
		if ( !hMarine )
			continue;
		
		if ( !hHud )
			hHud = InitHud( hMarine );
			
		local hHudMarine = hHud.GetEntity(0);
			
		if ( hHudMarine != hMarine )
			hHud.SetEntity( 0, hMarine );
	}

	// check if there are any huds attached to wrong marines
	local hHud = null;
	while ( hHud = Entities.FindByClassname( hHud, "rd_hud_vscript" ) )
	{
		local hMarine = hHud.GetEntity(0);
		if ( !hMarine )
			continue;
		
		local strID = hHud.GetName().slice(7);

		if ( !hMarine.IsInhabited() || !hMarine.GetCommander() || GetNetworkID( hMarine.GetCommander() ) != strID )
			hHud.SetEntity( 0, null );
	}
}

function Thinker_AlienIdentifier()
{
	foreach( strAlien, nWorth in AlienWorth_t )
	{
		local hAlien = null;
		while ( hAlien = Entities.FindByClassname( hAlien, strAlien ) )
			if ( !EntityOutputs.HasAction( hAlien, "OnDeath" ) )
				EntityOutputs.AddOutput( hAlien, "OnDeath", "worldspawn", "RunScriptCode", "AlienDied( caller, activator )", 0.0, 1 );
	}
}
