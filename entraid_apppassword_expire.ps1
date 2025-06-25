<#	
	.NOTES
	===========================================================================
	 Created on:   	25.06.2025
	 Created by:   	Timo Bobsien
	 Organization: 	eXemptec GmbH
	 Filename:     	entraid_apppassword_expire.ps1
	===========================================================================
	.DESCRIPTION
		This script send an e-mail, when a microsoft entra application secret expires in x days.
		Please change all variables on the top with your requirements. Please use no clear passwords, only use encrypted passwords from your system or like a password safe. Change the script to meet your security requirements.
#>

# ----- Change variables here -----

$sendto = "helpdesk@exemptec.eu"
$sendfrom = "noreply@example.eu"
$mailpassword = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

$warningdays = 60

$TenantID = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$AppID = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$AppSecret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# ----- Do not change here -----

$date = (Get-Date).AddDays($warningdays).ToUniversalTime()

$expirereport = @()

$password = ConvertTo-SecureString $mailpassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($sendfrom, $password)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ResourceAppIDuri = "https://graph.microsoft.com"
$oauthUri = "https://login.microsoftonline.com/$TenantID/oauth2/token"
$body = [Ordered] @{
    resource = "$ResourceAppIDuri"
    client_id = "$AppID"
    client_secret = "$AppSecret"
    grant_type = 'client_credentials'
}
$response = Invoke-RestMethod -Method Post -Uri $oauthUri -Body $body -ErrorAction Stop
$aadToken = $response.access_token

$headers = @{
    'Content-Type' = 'application/json'
     Accept = 'application/json'
     Authorization = "Bearer $aadToken"
        } 

$uri =  "https://graph.microsoft.com/v1.0/applications"
$applicationlist = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

$report = $applicationlist | Select-Object -ExpandProperty value | Select-Object `Displayname, @{Name="displaynamePW"; Expression={ $_.passwordCredentials.displayname}}, @{Name="enddatetime"; Expression={ $_.passwordCredentials.enddatetime}}

foreach($application in $report)
{
    #$application
    if($application.enddatetime)
    {
        foreach($appdate in $application.enddatetime)
        {
            $datesplit = $appdate -split "T"
            [datetime]$dateapplication = $datesplit[0]

            #Write-Host "Datum zum konvertieren: " $dateapplication

            if($dateapplication -lt $date)
            {
                #Write-Host "Application Password expire Warning for " $application.displayName 
                $expirereport += "Application: " + $application.displayName + " - Date: " + $dateapplication

            }
        }
    }
}

if($expirereport)
{
    $body = "Following application-passwords are expire in EntraID:`r`n"
    foreach($expire in $expirereport)
    {
        $body += $expire + "`r`n"
    }
    Send-MailMessage -From $cred.Username -To $sendto -Subject "EntraID Application Password Expire" -Body $body -SmtpServer smtp.office365.com -Credential $cred -UseSsl -Port 587
}
