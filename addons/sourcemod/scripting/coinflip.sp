#include <sourcemod>
#include <sdktools>
#include <store>
#include <colorvariables>

#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.1"
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
	char arg[64];
	GetCmdArgString(arg, sizeof(arg));
	
	int randomNum = GetRandomInt(0, 1);
	
	int curCredits = Store_GetClientCredits(client);
	int betCredits = StringToInt(arg);
	
	float wonCredits = betCredits * winRatio.FloatValue;
	
	if(waitTime[client] == 0) {
		if(args < 1 || args > 1) {
			CPrintToChat(client, "%s %t", prefix, "Invalid Arguments");
		} else if(args == 1) {
			if(curCredits > betCredits) {
				if(betCredits >= minBet.IntValue) {
					if(betCredits <= maxCredits.IntValue) {
						
						// If not configured otherwise; put client into wait time
						if(waitTimeLength.FloatValue > 0) {
							waitTime[client] = 1;
							CreateTimer(waitTimeLength.FloatValue, waitTimeTimer, client);
						}
						
						if(randomNum == 0) {
							// Loss
							CPrintToChat(client, "%s %t", prefix, "Client Lost");
							
							Store_SetClientCredits(client, (Store_GetClientCredits(client) - betCredits));
						} else if(randomNum == 1) {
							// Win!
							CPrintToChat(client, "%s %t", prefix, "Client Won", RoundToFloor(wonCredits));
							CPrintToChatAll("%s %t", prefix, "Client Won Announce", client, RoundToFloor(wonCredits));
							
							Store_SetClientCredits(client, (Store_GetClientCredits(client) + RoundToFloor(wonCredits)));
						}
						
					} else {
						// Too many credits put into bet
						CPrintToChat(client, "%s %t", prefix, "Too Many Credits", maxCredits.IntValue);
					}
				} else {
					CPrintToChat(client, "%s %t", prefix, "Too Few Credits", minBet.IntValue);
				}
			} else {
				// Not enough credits
				CPrintToChat(client, "%s %t", prefix, "Not Enough Credits", curCredits);
			}
			
		}
	} else {
		// Client is in waittime
		CPrintToChat(client, "%s %t", prefix, "Wait Time");
	}
	
	return Plugin_Handled;
}

public Action waitTimeTimer(Handle timer, int client) {
	if(IsClientInGame(client)) {
		
		waitTime[client] = 0;
		CPrintToChat(client, "%s %t", prefix, "Wait Time Over");
		
	}
}