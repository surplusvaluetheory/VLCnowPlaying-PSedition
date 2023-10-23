# VLC Now Playing to Twitch Script

This project contains a PowerShell script `vlcnowplaying.ps1` that connects to a Twitch chat and displays currently playing titles from VLC upon command.

## Requirements

- PowerShell
- VLC media player
- Twitch account for the bot to send messages. This can be your account or a new, separate account just for responding to these commands.

## Setup

### Set Up VLC's Web Interface

1. Open VLC, go to `Tools -> Preferences`.
2. Select `All` under `Show settings`.
3. From the left panel, navigate to `Interface -> Main interfaces` and check the `Web` box.
4. Go to `Interface -> Main interfaces -> Lua` and set a password under `Lua HTTP`. Note down this password as you'll need it in the Python script.
5. Save your changes and restart VLC.

### Get your oauth token to authenticate to chat

1. Get your OAuth token from [Twitch Token Generator](https://twitchtokengenerator.com/). This is similar to your password although the scope of permissions are limited to read and write chat by default. Be careful to not share with anyone.
2. Note down your Twitch username and the name of the Twitch channel where you want the bot to send messages.

### Set Up the PowerShell Script

1. Rename the `example.env` file to `.env`.
2. Open `.env` in your preferred text editor.
3. Update the variables with the relevant information:

```
# Password for the  web interface
_PASSWORD=yourpassw0rd

# Your Twitch username
TWITCH_USERNAME=yourtwitchusername

# Your Twitch OAuth token for authenticating the bot
TWITCH_OAUTH_TOKEN=oauthtokenfromtwitchtokengeneratororwhereveryougotit

# The Twitch channel where the bot will operate
TWITCH_CHANNEL=yourtwitchchannel

# Cooldown time in seconds for the commands
COMMAND_COOLDOWN=30

# Commands that trigger the bot to send the currently playing title in .
# Separate multiple commands with commas.
COMMANDS=!np,!nowplaying,!current

```

#### Execution Policy

You may also need to set the PowerShell execution policy to run the script. Open PowerShell as an administrator and run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

or for the current user:

```powershell
Set-ExecutionPolicy -Scope CurrentUser remotesigned
```

## Usage

After updating the `.env` file and setting the execution policy, run the PowerShell script.

```
nowplaying.ps1
```

Your bot should now be running, and it will display currently playing  title or filename in the Twitch chat when triggered by the `!np` command (or whichever commands you've specified in the .env file.



## Troubleshooting

If you encounter any issues, make sure VLC's web interface is correctly set up and accessible by visiting `http://localhost:8080` in your web browser. Also, make sure the `.env` file is correctly formatted and the values are correct. Finally, make sure you have the necessary permissions to send messages in the Twitch channel.
