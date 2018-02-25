# PowerTools ReadMe
A module containing a random collection of functions that I use occasionally. These originated as separate scripts but were merged into a module for transportability.
- Connect-Database
- Connect-TCPPort
- Convert-ADTimestamp
- Export-Password
- Get-FirewallStatus
- Get-IniValue
- Get-Netstat
- Get-ProcessorAffinity
- Get-ProcessorUtilisation
- Get-Screenshot
- Get-Uptime
- Get-Hash
- Import-Password
- Remove-IniValue
- Remove-WordMetadata
- Rename-FileExtension
- Select-Tail
- Select-Top
- Set-IniValue
- Set-ProcessorAffinity
- Show-WordMetadata
- Start-NetworkTrace
- Stop-NetworkTrace
- Test-Database
- Test-TCPPort
- Test-IsPasswordPwned

---
## Connect-Database
### DESCRIPTION
Tests logon connectivity to MS SQL Database. Supports SQL user authentication, or integrated Windows authentication. Returns connections details (connection status, time to connect) on success or failure. Use ```Test-Database``` instead if you only need a true/false result. 
### SYNTAX
```PowerShell
Connect-Database [-Server] <String> [-Database] <String> [-Username] <String> [[-Password] <SecureString>] [<CommonParameters>]

Connect-Database [-Server] <String> [-Database] <String> [[-UseWindowsAuthentication]] [<CommonParameters>]
```
### PARAMETERS
```-Server <String>```
The Hostname or IP address of the SQL server to connect to. If connecting to a named instance, include the instance name e.g. server\instance. If connecting to a SQL Availability Group you can use the name of the Availability Group Listener for this parameter.

```-Database <String>```
The name of the database to connect to.

```-Username <String>```
The SQL user account used to authenticate to the database.

```-Password <SecureString>```
The password associated with the SQL user account. Must be a Secure String. Omit this parameter to be prompted for the password (if the -SQLUser parameter has been supplied).

```-UseWindowsAuthentication [<SwitchParameter>]```
Use the current logged on user's credentials to authenticate using Windows authentication. This is the default action if no SQL user credentials are provided.

### EXAMPLE
```
PS C:\> Connect-Database -Server sqlserver01\SQLInst01 -Database testdb -UseWindowsAuthentication

Connection  : Successful
ElapsedTime : 0.0208364
Server      : sqlserver01\SQLInst01
Database    : testdb
User        : Windows (rob)
```
---