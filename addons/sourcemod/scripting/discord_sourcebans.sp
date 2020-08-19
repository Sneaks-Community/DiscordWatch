#include <sourcemod>
#include <discord>

#define PLUGIN_VERSION "1.2"

#define MSG_BAN "{\"attachments\": [{\"color\": \"{COLOR}\",\"title\": \"View on Sourcebans\",\"title_link\": \"{SOURCEBANS}\",\"fields\": [{\"title\": \"Player\",\"value\": \"{NICKNAME}\",\"short\": true},{\"title\": \"Steam ID\",\"value\": \"[{STEAMID}](https://steamcommunity.com/profiles/{STEAMID64})\",\"short\": true},{\"title\": \"Admin\",\"value\": \"{ADMIN}\",\"short\": true},{\"title\": \"Server\",\"value\": \"{HOSTNAME}\",\"short\": true},{\"title\": \"Ban Length\",\"value\": \"{BANLENGTH}\",\"short\": true},{\"title\": \"Reason\",\"value\": \"{REASON}\",\"short\": true}],\"footer\": \"DiscordWatch\",\"ts\": \"{TIMESTAMP}\"}]}"

ConVar g_cColor = null;
ConVar g_cSourcebans = null;
ConVar g_cConsole = null;
ConVar g_cWebhook = null;

public Plugin myinfo = 
{
	name = "DiscordWatch: SourceBans",
	author = ".#Zipcore, sneaK",
	description = "",
	version = PLUGIN_VERSION,
	url = "www.zipcore.net"
}

public void OnPluginStart()
{
	CreateConVar("discord_sourcebans_version", PLUGIN_VERSION, "Discord SourceBans version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cColor = CreateConVar("discord_sourcebans_color", "#ff2222", "Discord/Slack attachment color.");
	g_cSourcebans = CreateConVar("discord_sourcebans_url", "https://snksrv.com/bans/index.php?p=banlist&searchText={STEAMID}", "Link to sourcebans.");
	g_cConsole = CreateConVar("discord_sourcebans_console", "1", "Enable/Disable logging for bans from the console");
	g_cWebhook = CreateConVar("discord_sourcebans_webhook", "sourcebans", "Config key from configs/discord.cfg.");
	
	AutoExecConfig(true, "discord_sourcebans");
}

public void SBPP_OnBanPlayer(int iAdmin, int iTarget, int iTime, const char[] sReason)
{
	char sColor[8];
	g_cColor.GetString(sColor, sizeof(sColor));
	
	char sAuth[32];
	GetClientAuthId(iTarget, AuthId_Steam2, sAuth, sizeof(sAuth));
	
	char sAuth64[32];
	GetClientAuthId(iTarget, AuthId_SteamID64, sAuth64, sizeof(sAuth64));
	
	char sName[32];
	GetClientName(iTarget, sName, sizeof(sName));

	char sAdminName[32];
	char sAdminAuth[32];
	char sAdminAuth64[32];
	char sAdminField[256];
	if ((iAdmin == 0) && !GetConVarBool(g_cConsole))
	{
		return;
	}
	if (iAdmin >= 1)
	{
		GetClientName(iAdmin, sAdminName, sizeof(sAdminName));
		GetClientAuthId(iAdmin, AuthId_Steam2, sAdminAuth, sizeof(sAdminAuth));
		GetClientAuthId(iAdmin, AuthId_SteamID64, sAdminAuth64, sizeof(sAdminAuth64));
		Format(sAdminField, sizeof(sAdminField), "%s ([%s](https://steamcommunity.com/profiles/%s))", sAdminName, sAdminAuth, sAdminAuth64)
	}
	else
	{
		Format(sAdminField, sizeof(sAdminField), "CONSOLE")
	}

	char sHostName[128];
	GetConVarString(FindConVar("hostname"), sHostName, sizeof(sHostName));
	
	char sLength[32];
	if(iTime == 0)
	{
		sLength = "Permanent";
	}
	else if (iTime >= 525600)
	{
		int years = RoundToFloor(iTime / 525600.0);
		Format(sLength, sizeof(sLength), "%d mins (%d year%s)", iTime, years, years == 1 ? "" : "s");
    }
	else if (iTime >= 10080)
	{
		int weeks = RoundToFloor(iTime / 10080.0);
		Format(sLength, sizeof(sLength), "%d mins (%d week%s)", iTime, weeks, weeks == 1 ? "" : "s");
    }
	else if (iTime >= 1440)
	{
		int days = RoundToFloor(iTime / 1440.0);
		Format(sLength, sizeof(sLength), "%d mins (%d day%s)", iTime, days, days == 1 ? "" : "s");
    }
	else if (iTime >= 60)
	{
		int hours = RoundToFloor(iTime / 60.0);
		Format(sLength, sizeof(sLength), "%d mins (%d hour%s)", iTime, hours, hours == 1 ? "" : "s");
    }
	else if (iTime > 0) Format(sLength, sizeof(sLength), "%d min%s", iTime, iTime == 1 ? "" : "s");
	else return;
    
	Discord_EscapeString(sName, strlen(sName));
	Discord_EscapeString(sAdminName, strlen(sAdminName));
	Discord_EscapeString(sHostName, strlen(sHostName));

	int gettime = GetTime();
	char szTimestamp[64]; IntToString(gettime, szTimestamp, sizeof(szTimestamp));
	
	char sMSG[4096] = MSG_BAN;
	
	char sSourcebans[512];
	g_cSourcebans.GetString(sSourcebans, sizeof(sSourcebans));
	
	ReplaceString(sMSG, sizeof(sMSG), "{COLOR}", sColor);
	ReplaceString(sMSG, sizeof(sMSG), "{SOURCEBANS}", sSourcebans);
	ReplaceString(sMSG, sizeof(sMSG), "{STEAMID}", sAuth);
	ReplaceString(sMSG, sizeof(sMSG), "{STEAMID64}", sAuth64);
	ReplaceString(sMSG, sizeof(sMSG), "{REASON}", sReason);
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