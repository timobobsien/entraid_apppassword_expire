# entraid_apppassword_expire

This short script send a email to a specified address when a microsoft entraID Application secret is about to expire.

## Quickstart

First you need in your microsoft tenant a entra application with following permissions:
- Microsoft Graph: Directory.Read.All
- Microsoft Graph: Application.Read.All

This script use a password secret to access the graph api via the registered application.

After that, download the script to your system and configure a scheduled task / cron job like daily, weekly or what you need. 
Change in the script tie variables on the top for e-mail, entra application and the days the warning should be send before the secret expire.

Important: Change the password source to your requrements. Please not use plain passwords in this script. 
