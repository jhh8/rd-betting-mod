function LevelToRank( nLevel )
{
	if ( nLevel == 1 )
		return "Potato Player";
	
	if ( nLevel <= 3 )
		return "Landing Enjoyer";
		
	if ( nLevel <= 6 )
		return "Xenomite Eater";
		
	if ( nLevel <= 9 )
		return "Grub Stomper";
	
	if ( nLevel <= 12 )
		return "Experienced Marine";
		
	if ( nLevel <= 14 )
		return "Horde Destroyer";
		
	if ( nLevel <= 17 )
		return "Veteran Marine";
		
	if ( nLevel <= 20 )
		return "Swarm's Nightmare";
		
	return "Queen Slayer";
}

function LevelToColor( nLevel )
{
	if ( nLevel == 1 )
		return Vector( 182, 114, 78 );
	
	if ( nLevel <= 3 )
		return Vector( 192, 142, 67 );
		
	if ( nLevel <= 6 )
		return Vector( 217, 172, 129 );
		
	if ( nLevel <= 9 )
		return Vector( 208, 202, 196 );
	
	if ( nLevel <= 12 )
		return Vector( 140, 191, 193 );
		
	if ( nLevel <= 14 )
		return Vector( 129, 114, 114 );
		
	if ( nLevel <= 17 )
		return Vector( 88, 154, 121 );
		
	if ( nLevel <= 20 )
		return Vector( 151, 181, 62 );
		
	return Vector( 213, 204, 47 );
}

function PointsToLevel( nPoints )
{
	local nLevel = 1;
	while ( nPoints >= LevelToPoints( nLevel ) )
		nLevel++;
		
	return nLevel;
}

function LevelToPoints( nLevel )
{
	local nPoints = ( 125.0 + pow( 1.25, nLevel ) * pow( nLevel, 1.5 ) * 100.0 ).tointeger();
	local nLen = nPoints.tostring().len();
	local nExp = pow( 10, ( pow( nLen, 0.75 ) - 0.31 ).tointeger() ).tointeger();
	
	nPoints = nPoints / nExp * nExp;
	
	return nPoints;
}