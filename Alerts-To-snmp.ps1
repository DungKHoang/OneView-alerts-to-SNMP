Param ( [string]$OVApplianceIP      ="",
        [string]$OVAdminName        ="Administrator", 
        [string]$OVAdminPassword    ="password",
        [string]$OneViewModule      = "HPOneView.410",  

        [dateTime]$Start              = (get-date -day 1) ,
        [dateTime]$End                = (get-date) , 
        [string]$Severity           = '',                 # default will be critical and warning

        [string]$OVAuthDomain       = "local"

)
#$ErrorActionPreference = 'SilentlyContinue'
$DoubleQuote    = '"'
$CRLF           = "`r`n"
$Delimiter      = "\"   # Delimiter for CSV profile file
$SepHash        = ";"   # USe for multiple values fields
$Sep            = ";"
$hash           = '@'
$SepChar        = '|'
$CRLF           = "`r`n"
$OpenDelim      = "{"
$CloseDelim     = "}" 
$CR             = "`n"
$Comma          = ','
$Equal          = '='
$Dot            = '.'
$Underscore     = '_'

$Syn12K                   = 'SY12000' # Synergy enclosure type

Function Prepare-OutFile ([string]$Outfile)
{

    $filename   = $outFile.Split($Delimiter)[-1]
    $ovObject   = $filename.Split($Dot)[0] 
    
    New-Item $OutFile -ItemType file -Force -ErrorAction Stop | Out-Null
    
    $HeaderText = "AlertTypeID|AlertDescription|snmpOID|CorrectiveAction"

    write-host -ForegroundColor Cyan "CSV file --> $((dir $outFile).FullName)"
    Set-content -path $outFile -Value $HeaderText
}


Function Out-ToScriptFile ([string]$Outfile)
{
    if ($ScriptCode)
    {
        Prepare-OutFile -outfile $OutFile
        
        Add-Content -Path $OutFile -Value $ScriptCode
        

    } 
}

import-module HPOneView.410




# ---------------- Connect to OneView appliance
#
write-host -ForegroundColor Cyan "-----------------------------------------------------"
write-host -ForegroundColor Cyan "Connect to the OneView appliance..."
write-host -ForegroundColor Cyan "-----------------------------------------------------"
$connection = Connect-HPOVMgmt -appliance $OVApplianceIP -user $OVAdminName -password $OVAdminPassword -LoginAcknowledge:$true -AuthLoginDomain $OVAuthDomain
$appliance = $connection.name
# ---------------------------
#  Generate Output files

$timeStamp          = get-date -format MMM-yyyy
    
$OutFile            = "alert-snmp-$appliance-$timeStamp.CSV"

$startDate          = $start.ToShortDateString()
$endDate            = $end.ToShortDateString()
Write-Host -ForegroundColor Cyan "CSV file -->     $OutFile  "
write-host -ForegroundColor CYAN "##NOTE: Delimiter used in the CSV file is '|' "
Write-host -ForegroundColor CYAN "`nCollecting Alert from $StartDate to $endDate on OneView $appliance ....`n"
$scriptCode         =  New-Object System.Collections.ArrayList
if ( [string]::IsNullOrWhiteSpace($Severity))
{
    $ListofAlerts   = get-hpovalert -Start $Start -End $End | where {($_.Severity -eq 'Critical') -or ($_.Severity -eq 'Warning')}
}
else 
{
    $ListofAlerts   = get-hpovalert -Start $Start -End $End -Severity $Severity
}

foreach ($alert in $ListofAlerts)
{
    $alertDescription           = $alert.Description
    $alertTypeID                = $alert.alertTypeID
    $correctiveAction           = $alert.CorrectiveAction

    foreach ($eventUri in $alert.associatedEventUris)
    {
        if ($eventUri)
        {
            $ev      = send-HPOVRequest -uri $eventUri
            foreach ($evItem in $ev.eventDetails)
            {
                $eventName      = $evItem.eventItemName
                $eventSnmpOid   = $evItem.eventItemSnmpOid
                $value          = ""
                if ($eventName -match '^\d.')
                {
                    $value              = "$alertTypeID|$alertDescription|$eventName|$correctiveAction"
                    [void]$scriptCode.Add('{0}' -f $value)
                }
                else 
                {
                    if ($eventSnmpOid -match '^\d.')
                    {
                        $value          = "$alertTypeID|$alertDescription|$eventSnmpOid|$correctiveAction"
                        [void]$scriptCode.Add('{0}' -f $value) 
                    }

                }


            }
        }
    }
}
$scriptCode = $scriptCode.ToArray() 
Out-ToScriptFile -Outfile $outFile 


write-host -ForegroundColor Cyan "-----------------------------------------------------"
write-host -ForegroundColor Cyan "Disconnect from OneView appliance ................"
write-host -ForegroundColor Cyan "-----------------------------------------------------"

Disconnect-HPOVMgmt 