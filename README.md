# OV Alerts to SNMP

The script alerts-to-snmp.ps1 matches OV alerts with SNMP OID trap generated
This is useful in the scenraio where administrator wants to find OneView alerts that has SNMP OIID trap attached to it

## Prerequisites
The  script requires:
   * the latest OneView PowerShell library : https://github.com/HewlettPackard/POSH-HPOneView/releases


## Output
The script generates a CSV file containing: alertTypeID, alert description, SNMP OID and suggested corrective action 
The CSV file uses '|' as delimiter so if you want to view it correctly in Excel, you should use custom delimiter
Example
import-CSV -delimiter '|' file.csv | Out-GridView


## Syntax

```
    .\Alerts-To-snmp.ps1 -OVApplianceIP <OV-IP-Address> -OVAdminName <Admin-name> -OVAdminPassword <password> -Start <start-day-of-alert-collection> -End <end-day-of-alert-collection> -Severity <Critical,warning,OK>

```
Default values are:

   * Start : get-date -day 1   --> Beginning of current month
   * End   : get-date          --> today
   * Severity                  --> If not specified, only collect alerts with Severity = Critical and Warning
    
