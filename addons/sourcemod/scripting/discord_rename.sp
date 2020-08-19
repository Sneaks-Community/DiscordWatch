#include <sourcemod>
#include <discord>

#define PLUGIN_VERSION "1.0"

#define MSG_RENAME "{\"attachments\": [{\"color\": \"{COLOR}\",\"title\": \"Player Renamed\",\"fields\": [{\"title\": \"Player\",\"value\": \"{NICKNAME}\",\"short\": true},{\"title\": \"Steam ID\",\"value\": \"{STEAMID}\",\"short\": true},{\"title\": \"Admin\",\"value\": \"{ADMIN}\",\"short\": true},{\"title\": \"Server\",\"value\": \"{HOSTNAME}\",\"short\": true}],\"footer\": \"DiscordWatch\",\"ts\": \"{TIMESTAMP}\"}]}"

ConVar g_cColor = null;
ConVar g_cConsole = null;
ConVar g_cWebhook = null;

public Plugin myinfo = 
{
	name = "DiscordWatch: Rename",
	author = "sneaK",
	description = "Logs renames to Discord",
	version = PLUGIN_VERSION,
	url = "www.snksrv.com"
}

public void OnPluginStart()
{
	CreateConVar("discord_rename_version", PLUGIN_VERSION, "Discord Rename version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cColor = CreateConVar("discord_rename_color", "#00A6FF", "Discord/Slack attachment color.");
	g_cConsole = CreateConVar("discord_rename_console", "1", "Enable/Disable logging for console renames");
	g_cWebhook = CreateConVar("discord_rename_webhook", "action", "Config key from configs/discord.cfg.");
	
	AutoExecConfig(true, "discord_rename");

	//HookEvent("player_changename", NameChange);
}
/*
public Action NameChange(Handle event, const char[] name, bool dontBroadcast)
{
    char sNewName[MAX_NAME_LENGTH];
    GetEventString(event, "newname", sNewName, sizeof(sNewName));
}
*/

public Action OnLogAction(Handle source, Identity ident, int client, int target, const char[] message)
{
	if((StrContains(message, "renamed") != -1))
	{
		char sColor[8];
		g_cColor.GetString(sColor, sizeof(sColor));
		
		char sHostName[128];
		GetConVarString(FindConVar("hostname"), sHostName, sizeof(sHostName));
		
		char sTargetName[MAX_NAME_LENGTH];
		GetClientName(target, sTargetName, sizeof(sTargetName));
		
		char sTargetAuth[32];
		char sTargetAuth64[32];
		char sTargetField[256];
		if (!IsFakeClient(target))
		{
			GetClientAuthId(target, AuthId_Steam2, sTargetAuth, sizeof(sTargetAuth));
			GetClientAuthId(target, AuthId_SteamID64, sTargetAuth64, sizeof(sTargetAuth64));
			Format(sTargetField, sizeof(sTargetField), "[%s](https://steamcommunity.com/profiles/%s)", sTargetAuth, sTargetAuth64)
		}
		else
		{
			Format(sTargetField, sizeof(sTargetField), "BOT")
		}
		
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
		
		Discord_EscapeString(sTargetName, strlen(sTargetName));
		Discord_EscapeString(sAdminName, strlen(sAdminName));
		Discord_EscapeString(sHostName, strlen(sHostName));
		//Discord_EscapeString(sNewName), strlen(sNewName));
		
		int gettime = GetTime();
		char szTimestamp[64]; IntToString(gettime, szTimestamp, sizeof(szTimestamp));
		
		char sMSG[4096] = MSG_RENAME;
		
		ReplaceString(sMSG, sizeof(sMSG), "{COLOR}", sColor);
		ReplaceString(sMSG, sizeof(sMSG), "{HOSTNAME}", sHostName);
		ReplaceString(sMSG, sizeof(sMSG), "{STEAMID}", sTargetField);
		ReplaceString(sMSG, sizeof(sMSG), "{ADMIN}", sAdminField);
		ReplaceString(sMSG, sizeof(sMSG), "{NICKNAME}", sTargetName);
		//ReplaceString(sMSG, sizeof(sMSG), "{NEWNAME}", sNewName);
		ReplaceString(sMSG, sizeof(sMSG), "{TIMESTAMP}", szTimestamp);
		
		SendMessage(sMSG);
	}
}

SendMessage(char[] sMessage)
{
	char sWebhook[32];
	g_cWebhook.GetString(sWebhook, sizeof(sWebhook));
	Discord_SendMessage(sWebhook, sMessage);
}