# PowerTools ReadMe
A module containing a random collection of functions that I use occasionally. These originated as separate scripts but were merged into a module for transportability.
- Connect-Database
- Connect-TCPPort
- Convert-ADTimestamp
- Export-Credential
- Get-FirewallStatus
- Get-Hash
- Get-IniValue
- Get-Netstat
- Get-ProcessorAffinity
- Get-ProcessorUtilisation
- Get-Screenshot
- Get-Uptime
- Get-Hash
- Import-Credential
- Remove-IniValue
- Remove-WordMetadata
- Rename-FileExtension
- Rename-Filename
- Select-Tail
- Select-Top
- Set-IniValue
- Set-ProcessorAffinity
- Show-WordMetadata
- Start-NetworkTrace
- Stop-NetworkTrace
- Test-Database
- Test-IsPasswordPwned
- Test-TCPPort


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
## Connect-TCPPort
### DESCRIPTION
Tests connectivity to a TCP port on a remote host. If successful, the time to connect is displayed with the endpoint details.

### SYNTAX
```PowerShell
Connect-TCPPort [-Hostname] <String> [-Port] <Int32> [<CommonParameters>]
```
### PARAMETERS
```-Hostname <string>```The name or IP address of the remote host to connect to.

```-Port <Int32>``` The port number on the remote host to connect to. 

### EXAMPLE
```
PS C:\> Connect-TCPPort somehost.com -80

Connection ElapsedTime RemoteHost   Port
---------- ----------- ----------   ----
Successful 0.0165949   somehost.com 80

```

---
## Convert-ADTimestamp
### DESCRIPTION
Converts a integer timestamp (e.g. from LDIFDE or some AD CmdLets) to a date/time value.
### SYNTAX
```PowerShell
Convert-ADTimestamp [-Value] <string>  [<CommonParameters>]
```
### PARAMETERS
```-Value <string>```The value of the date/time field extracted from AD.

### EXAMPLE
```
PS C:\> Convert-ADTimestamp -Value 131200456520442703

Tuesday, 4 October 2016 5:07:32 PM
```

---
## cmdlet-name
### DESCRIPTION

### SYNTAX
```PowerShell

```
### PARAMETERS
```-Name <type>```

### EXAMPLE
```

```

---
## cmdlet-name
### DESCRIPTION

### SYNTAX
```PowerShell

```
### PARAMETERS
```-Name <type>```

### EXAMPLE
```

```

---
## cmdlet-name
### DESCRIPTION

### SYNTAX
```PowerShell

```
### PARAMETERS
```-Name <type>```

### EXAMPLE
```

```

---
## cmdlet-name
### DESCRIPTION

### SYNTAX
```PowerShell

```
### PARAMETERS
```-Name <type>```

### EXAMPLE
```

```

---
## cmdlet-name
### DESCRIPTION

### SYNTAX
```PowerShell

```
### PARAMETERS
```-Name <type>```

### EXAMPLE
```

```