#include <sourcemod>
#include <store>
#include <colorvariables>

#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.2"

char prefix[] = "{yellow}[CoinFlip] {default}";

int waitTime[MAXPLAYERS + 1];

ConVar maxCredits;
ConVar minBet;
ConVar winRatio;
ConVar waitTimeLength;

public Plugin myinfo = 
{
	name = "[STORE] Coinflip",
	author = "Hypr",
	description = "Ability to coinflip",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=276677"
};

public void OnPluginStart() {
	
	LoadTranslations("coinflip.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	RegConsoleCmd("sm_flip", sm_flip);
	
	AutoExecConfig(true, "store.coinflip");
	
	maxCredits = CreateConVar("sm_coinflip_max", "50", "What's the maximum amounts of credits a user can bet at once", FCVAR_NOTIFY, true, 1.0);
	winRatio = CreateConVar("sm_coinflip_winratio", "0.5", "The amount of the betted coins that the client wins. (Betted credits * 0.5)", FCVAR_NOTIFY, true, 0.1);
	minBet = CreateConVar("sm_coinflip_min", "5", "What's the minimum amount of credits a player is allowed to bet?", FCVAR_NOTIFY, true, 0.1);
	waitTimeLength = CreateConVar("sm_coinflip_waittime", "120", "In seconds, how long does a player have to wait inbetween bets?\nSet to 0 to disable.", FCVAR_NOTIFY);
}

public Action sm_flip(int client, int args) {

	if (!IsValidClient(client)) { // invalid client
		CPrintToChat(client, "%s %t", prefix, "Invalid Client"); 
		return Plugin_Handled;
	}
	
	if (args != 1) { // invalid argument count
		CPrintToChat(client, "%s %t", prefix, "Invalid Arguments");
		return Plugin_Handled;
	}
		
	if (waitTime[client] > GetTime()) { // still in cooldown
		CPrintToChat(client, "%s %t", prefix, "Wait Time");
		return Plugin_Handled;
	}
	
	char betAmount[64];
	GetCmdArg(1, betAmount, sizeof(betAmount));
	
	int curCredits = Store_GetClientCredits(client);
	int betCredits = StringToInt(betAmount);

	if (curCredits < betCredits) { // not enough credits
		CPrintToChat(client, "%s %t", prefix, "Not Enough Credits", curCredits);
		return Plugin_Handled;
	}
	
	if (betCredits < minBet.IntValue) { // bet is too small
		CPrintToChat(client, "%s %t", prefix, "Too Few Credits", minBet.IntValue);
		return Plugin_Handled;
	}
	
	if (betCredits > maxCredits.IntValue) { // bet is too big
		CPrintToChat(client, "%s %t", prefix, "Too Many Credits", maxCredits.IntValue);
		return Plugin_Handled;
	}
	
	
	// If configured, put client into wait time
	if(waitTimeLength.IntValue > 0) {
		waitTime[client] = GetTime() + waitTimeLength.IntValue;
	}
	
	switch (GetRandomInt(0, 1))
	{
		case 0:
		{
			CPrintToChat(client, "%s %t", prefix, "Client Lost");
			
			Store_SetClientCredits(client, (Store_GetClientCredits(client) - betCredits));
		}
		
		case 1:
		{
			float wonCredits = betCredits * winRatio.FloatValue;
			
			CPrintToChat(client, "%s %t", prefix, "Client Won", RoundToFloor(wonCredits));
			CPrintToChatAll("%s %t", prefix, "Client Won Announce", client, RoundToFloor(wonCredits));
			
			Store_SetClientCredits(client, (Store_GetClientCredits(client) + RoundToFloor(wonCredits)));
		}
	}
	
	return Plugin_Handled;
}

bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}