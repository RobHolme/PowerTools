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
- Get-ADUserDetails
- Get-ADGroupMembership


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
```-Hostname <string>``` The name or IP address of the remote host to connect to.

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
```-Value <string>``` The value of the date/time field extracted from AD.

### EXAMPLE
```
PS C:\> Convert-ADTimestamp -Value 131200456520442703

Tuesday, 4 October 2016 5:07:32 PM
```

---
## Export-Credential
### DESCRIPTION
Exports a password to a file (as a secure string). The file format is XML. The password is encrypted, requiring the same user and host to be able to read the password. The exported password can not be transported between hosts or users, it will fail to import.

Use Import-Password to return the PS Credential object from file.

### SYNTAX
```PowerShell
Export-Credential [-Path] <String> [-Password] <SecureString> [[-Username] <String>] [-NoClobber] [<CommonParameters>]

Export-Credential [-Path] <String> [[-Credential] <PSCredential>] [-NoClobber] [<CommonParameters>]
```
### PARAMETERS
```-Path <String>``` The Hostname or IP address of the SQL server to connect to. If connecting to a named instance, include the instance name e.g. server\instance

```Password <SecureString>``` The password (as a secure string). Plain text password not allowed.

```-Username <String>``` The (optional) username to store with the password.

```-Credential <PSCredential>``` The credential object containing the credentials to export.

```-NoClobber [<SwitchParameter>]``` Prevent to function from overwriting existing files.

### EXAMPLE
```
PS C:\>Export-Credential -Path c:\temp\password.xml -Credential (Get-Credential)

PS C:\>Export-Credential -Path c:\temp\password.xml -Username testdomain\testuser -Password $securePassword
```

---
## Get-FirewallStatus
### DESCRIPTION
Identifies if the firewall is enabled for the Domain, Private, and Public network profiles.

Supports Windows Powershell only.
### SYNTAX
```PowerShell
Get-FirewallStatus [<CommonParameters>]
```

### EXAMPLE
```
PS C:\> Get-FirewallStatus

ProfileName Enabled
----------- -------
Domain         True
Private        True
Public         True
```

---
## Get-Hash
### DESCRIPTION
Generate the hash of a string or file. Supports MD5, SHA1, SHA256, SHA384, SHA512
### SYNTAX
```PowerShell
Get-Hash [-Path] <String[]> [-Algorithm] <String> [<CommonParameters>]

Get-Hash [-LiteralPath] <String[]> [-Algorithm] <String> [<CommonParameters>]

Get-Hash [-String] <String> [-Algorithm] <String> [<CommonParameters>]
```
### PARAMETERS
```-String <String>``` The string to generate the hash for.

```-Path <String[]>``` The file to generate the hash for. Accepts wildcards.

```-LiteralPath <String[]>``` The file to generate the hash for (Literal path).
### EXAMPLE
```
PS C:\> Get-Hash -String "Some String" -Algorithm MD5

Algorithm Hash
--------- ----
MD5       83beb8c4fa4596c8f7b565d390f494e2
```

```
PS C:\> Get-Hash -Path *.png -Algorithm SHA1

Algorithm Hash                                     Filename
--------- ----                                     --------
SHA1      5c87f9db340eec992867cd7448fc8e8518b71e95 test-1.png
SHA1      2c59ecf75188b9a7496b13a78b5a9e1fb113fcef test-2.png
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