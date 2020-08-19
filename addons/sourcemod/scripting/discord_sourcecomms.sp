#include <sourcemod>
#include <discord>

#define PLUGIN_VERSION "1.2"

#define MSG_BAN "{\"attachments\": [{\"color\": \"{COLOR}\",\"title\": \"View on Sourcebans\",\"title_link\": \"{SOURCEBANS}\",\"fields\": [{\"title\": \"Player\",\"value\": \"{NICKNAME}\",\"true\": false},{\"title\": \"Steam ID\",\"value\": \"[{STEAMID}](https://steamcommunity.com/profiles/{STEAMID64})\",\"true\": false},{\"title\": \"Admin\",\"value\": \"{ADMIN}\",\"short\": true},{\"title\": \"Server\",\"value\": \"{HOSTNAME}\",\"short\": true},{\"title\": \"{COMMTYPE} Length\",\"value\": \"{BANLENGTH}\",\"short\": true},{\"title\": \"Reason\",\"value\": \"{REASON}\",\"short\": true}],\"footer\": \"DiscordWatch\",\"ts\": \"{TIMESTAMP}\"}]}"

ConVar g_cColorGag = null;
ConVar g_cColorMute = null;
ConVar g_cColorSilence = null;
ConVar g_cSourcebans = null;
ConVar g_cConsole = null;
ConVar g_cWebhook = null;

public Plugin myinfo = 
{
	name = "DiscordWatch: SourceComms",
	author = ".#Zipcore, sneaK",
	description = "",
	version = PLUGIN_VERSION,
	url = "www.zipcore.net"
}

public void OnPluginStart()
{
	CreateConVar("discord_sourcecomms_version", PLUGIN_VERSION, "Discord SourceComms version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cColorGag = CreateConVar("discord_sourcecomms_color_gag", "#ffff22", "Discord/Slack attachment gag color.");
	g_cColorMute = CreateConVar("discord_sourcecomms_color_mute", "#2222ff", "Discord/Slack attachment mute color.");
	g_cColorSilence = CreateConVar("discord_sourcecomms_color_silence", "#ff22ff", "Discord/Slack attachment silence color.");
	g_cSourcebans = CreateConVar("discord_sourcecomms_url", "https://snksrv.com/bans/index.php?p=commslist&searchText={STEAMID}", "Link to sourcebans.");
	g_cConsole = CreateConVar("discord_sourcebans_console", "1", "Enable/Disable logging for comms enforcement from the console");
	g_cWebhook = CreateConVar("discord_sourcecomms_webhook", "sourcecomms", "Config key from configs/discord.cfg.");
	
	AutoExecConfig(true, "discord_sourcecomms");
}

public int SourceComms_OnBlockAdded(int client, int target, int time, int type, char[] reason)
{
	PrePareMsg(client, target, time, type, reason);
}

public int PrePareMsg(int client, int target, int time, int type, char[] reason)
{
	char sAuth[32];
	GetClientAuthId(target, AuthId_Steam2, sAuth, sizeof(sAuth));
	
	char sAuth64[32];
	GetClientAuthId(target, AuthId_SteamID64, sAuth64, sizeof(sAuth64));
	
	char sName[32];
	GetClientName(target, sName, sizeof(sName));
	
	char sAdminName[32];
	char sAdminAuth[32];
	char sAdminAuth64[32];
	char sAdminField[256];
	if ((client == 0) && !GetConVarBool(g_cConsole))
	{
		return;
	}
	if (client >= 1)
	{
		GetClientName(client, sAdminName, sizeof(sAdminName));
		GetClientAuthId(client, AuthId_Steam2, sAdminAuth, sizeof(sAdminAuth));
		GetClientAuthId(client, AuthId_SteamID64, sAdminAuth64, sizeof(sAdminAuth64));
		Format(sAdminField, sizeof(sAdminField), "%s ([%s](https://steamcommunity.com/profiles/%s))", sAdminName, sAdminAuth, sAdminAuth64)
	}
	else
	{
		Format(sAdminField, sizeof(sAdminField), "CONSOLE")
	}

	char sHostName[128];
	GetConVarString(FindConVar("hostname"), sHostName, sizeof(sHostName));
	
	char sLength[32];
	if(time < 0)
	{
		sLength = "Session";
	}
	else if(time == 0)
	{
		sLength = "Permanent";
	}
	else if (time >= 525600)
	{
		int years = RoundToFloor(time / 525600.0);
		Format(sLength, sizeof(sLength), "%d mins (%d year%s)", time, years, years == 1 ? "" : "s");
    }
	else if (time >= 10080)
	{
		int weeks = RoundToFloor(time / 10080.0);
		Format(sLength, sizeof(sLength), "%d mins (%d week%s)", time, weeks, weeks == 1 ? "" : "s");
    }
	else if (time >= 1440)
	{
		int days = RoundToFloor(time / 1440.0);
		Format(sLength, sizeof(sLength), "%d mins (%d day%s)", time, days, days == 1 ? "" : "s");
    }
	else if (time >= 60)
	{
		int hours = RoundToFloor(time / 60.0);
		Format(sLength, sizeof(sLength), "%d mins (%d hour%s)", time, hours, hours == 1 ? "" : "s");
    }
	else Format(sLength, sizeof(sLength), "%d min%s", time, time == 1 ? "" : "s");
    
	Discord_EscapeString(sName, strlen(sName));
	Discord_EscapeString(sAdminName, strlen(sAdminName));
	Discord_EscapeString(sHostName, strlen(sHostName));
	
	char sMSG[4096] = MSG_BAN;
	
	char sSourcebans[512];
	g_cSourcebans.GetString(sSourcebans, sizeof(sSourcebans));
	
	char sColor[512];
	char sType[64];
	
	switch(type)
	{
		case 1: 
		{
			g_cColorMute.GetString(sColor, sizeof(sColor));
			sType = "Mute";
		}
		case 2: 
		{
			g_cColorGag.GetString(sColor, sizeof(sColor));
			sType = "Gag";
		}
		case 3: 
		{
			g_cColorSilence.GetString(sColor, sizeof(sColor));
			sType = "Silence";
		}
	}

	int gettime = GetTime();
	char szTimestamp[64]; IntToString(gettime, szTimestamp, sizeof(szTimestamp));
	
	ReplaceString(sMSG, sizeof(sMSG), "{COLOR}", sColor);
	ReplaceString(sMSG, sizeof(sMSG), "{COMMTYPE}", sType);
	ReplaceString(sMSG, sizeof(sMSG), "{SOURCEBANS}", sSourcebans);
	ReplaceString(sMSG, sizeof(sMSG), "{STEAMID}", sAuth);
	ReplaceString(sMSG, sizeof(sMSG), "{STEAMID64}", sAuth64);
	ReplaceString(sMSG, sizeof(sMSG), "{REASON}", reason);
	ReplaceString(sMSG, sizeof(sMSG), "{BANLENGTH}", sLength);
	ReplaceString(sMSG, sizeof(sMSG), "{ADMIN}", sAdminField);
	ReplaceString(sMSG, sizeof(sMSG), "{NICKNAME}", sName);
	ReplaceString(sMSG, sizeof(sMSG), "{HOSTNAME}", sHostName);
	ReplaceString(sMSG, sizeof(sMSG), "{TIMESTAMP}", szTimestamp);
	
	SendMessage(sMSG);
}

SendMessage(char[] sMessage)
{
	char sWebhook[32];
	g_cWebhook.GetString(sWebhook, sizeof(sWebhook));
	Discord_SendMessage(sWebhook, sMessage);
}