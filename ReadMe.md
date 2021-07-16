# PowerTools ReadMe
A module containing a random collection of functions that I use occasionally. These originated as separate scripts but were merged into a module for transportability.
 - Add-SshAuthorizedKey    
 - Export-Credential       
 - Get-Hash                
 - Get-Netstat             
 - Get-Screenshot     
 - Get-SMBShareCapacity     
 - Import-Credential       
 - Rename-FileExtension    
 - Rename-Filename         
 - Start-NetworkTrace      
 - Start-TCPListener       
 - Stop-NetworkTrace       
 - Test-IsPasswordPwned    
 - Test-SQLDatabase        
 - Test-TCPPort            
 - Test-URL


---
## Add-SshAuthorizedKey
### DESCRIPTION
Adds a SSH public key to authorized_keys on a server.
### SYNTAX
```PowerShell
Add-SshAuthorizedKey [-Path] <String[]> [-User] <String> [-Server] <String[]> [[-OverwriteExistingKeys]] [<CommonParameters>]

Add-SshAuthorizedKey [-LiteralPath] <String[]> [-User] <String> [-Server] <String[]> [[-OverwriteExistingKeys]] [<CommonParameters>]
```
### PARAMETERS
```-Path <String>``` The full path of the public key file. Accepts wildcards to match more than one public key.

```-LiteraPath <String>``` The full path and filename of the file to export the credentials to (Literal Path).

```-User <String>``` The ssh username used to connect to the server.

```-Server <String>``` The ssh host to connect to.

```-OverwriteExistingKeys [<SwitchParameter>]``` Overwrite all existing keys in authorized_keys file (if this isn;t set the default is to append to this file)
### EXAMPLE
```
Add-SshAuthorizedKey -Path H:\Documents\.ssh\all-servers_rsa.pub -User rob -Server server1,server2,server3
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
```-Path <String>``` The full path and filename of the file to export the credentials to.

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

## Get-Netstat
### DESCRIPTION
A wrapper for netstat that resolves process ID's to process names.
### SYNTAX
```PowerShell
Get-Netstat [[-ResolveIPAddress]] [<CommonParameters>]
```
### PARAMETERS
```-ResolveIPAddress <SwitchParameter>``` Resolve IP addresses to hostnames (slow).

### EXAMPLE
```
Get-Netstat

```
### EXAMPLE
```
PS C:\> Get-Netstat | Where-Object {$_.ProcessName -eq "msedge"}

Protocol LocalIPAddress LocalPort RemoteIPAddress RemotePort State       ProcessName
-------- -------------- --------- --------------- ---------- -----       -----------
TCP      0.0.0.0        11124     0.0.0.0         0          Bound       msedge
TCP      0.0.0.0        10862     0.0.0.0         0          Bound       msedge
TCP      10.168.20.173  11124     140.82.112.25   443        Established msedge
TCP      10.168.20.173  10862     13.107.6.160    443        Established msedge
UDP      ::             5353                                             msedge
UDP      0.0.0.0        5353                                             msedge

```
---
## Get-ProcessorAffinity
### DESCRIPTION
 Reports the number of processor cores (incl hyper-threaded 'core') that a process can run on.
### SYNTAX
```PowerShell
Get-ProcessorAffinity [-ProcessName] <String> [<CommonParameters>]

Get-ProcessorAffinity -ProcessID <Int32> [<CommonParameters>]
```
### PARAMETERS
```-ProcessName <String>``` The name of the process. Can use wildcards to return more than one process name.

```-ProcessID <Int>``` The process ID (PID)
### EXAMPLE
```
PS c:\> Get-ProcessorAffinity -ProcessName msedge

ProcessID Cores ProcessName
--------- ----- -----------
     7380     4 msedge
    10376     4 msedge
    12276     4 msedge
    14296     4 msedge
    16004     4 msedge
    18700     4 msedge
    19908     4 msedge
    20144     4 msedge
    21896     4 msedge
    23072     4 msedge
```

### EXAMPLE
```
Get-ProcessorAffinity -ProcessName m*

ProcessID Cores ProcessName
--------- ----- -----------
     4520     0 MCEBuddy.Service
     4244     0 mDNSResponder
     2288     0 Memory Compression
    11132     4 Microsoft.Photos
    10708     0 mmc
    19320     4 mobsync
     8384     0 MoUsoCoreWorker
     7380     4 msedge
    10376     4 msedge
    12276     4 msedge
    14296     4 msedge
    16004     4 msedge
    18700     4 msedge
    19908     4 msedge
    20144     4 msedge
    21896     4 msedge
    23072     4 msedge
     4764     0 MsMpEng
```

### EXAMPLE
```
 Get-ProcessorAffinity -ProcessID 10376

ProcessID Cores ProcessName
--------- ----- -----------
    10376     4 msedge
```

---
## Get-ProcessorUtilisation
### DESCRIPTION
Display the overall processor utilisation and process utilisation stats.
This function is not supported under Powershell Core.
### SYNTAX
```PowerShell
Get-ProcessorUtilisation [-Top <Int32>] [<CommonParameters>]

Get-ProcessorUtilisation [-ProcessName <String[]>] [<CommonParameters>]
```
### PARAMETERS
```-Top <Int32>``` Limit the results to the top number of results (by highest CPU utilisation).

```-ProcessName <String[]>``` Limit results to specific process names.
### EXAMPLE
```
```

---
## Test-SQLDatabase
### DESCRIPTION
Tests logon connectivity to MS SQL Database. Supports SQL user authentication, or integrated Windows authentication. Returns connections details (connection status, time to connect) on success or failure. Use ```Test-Database``` instead if you only need a true/false result. 
### SYNTAX
```PowerShell
Test-Database [-Server] <String> [-Database] <String> [-Username] <String> [[-Password] <SecureString>] [<CommonParameters>]

Test-Database [-Server] <String> [-Database] <String> [[-UseWindowsAuthentication]] [<CommonParameters>]
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
PS C:\> Test-Database -Server sqlserver01\SQLInst01 -Database testdb -UseWindowsAuthentication

Connection  : Successful
ElapsedTime : 0.0208364
Server      : sqlserver01\SQLInst01
Database    : testdb
User        : Windows (TESTDOM\rob)
```

---
## Test-TCPPort
### DESCRIPTION
Tests connectivity to a TCP port on a remote host. If successful, the time to connect is displayed with the endpoint details.

### SYNTAX
```PowerShell
Test-TCPPort [-Hostname] <String> [-Port] <Int32> [-Timeout] <Int32> [<CommonParameters>]
```
### PARAMETERS
```-Hostname <string>``` The name or IP address of the remote host to connect to.

```-Port <Int32>``` The port number on the remote host to connect to. 

```-Timeout <Int32>``` The TCP connection timeout in seconds. Defaults to 5 seconds. System TCP timeout will still apply if lower than this value. 
### EXAMPLE
```
PS C:\> Connect-TCPPort somehost.com -80

Connection RemoteHost   RemoteAddress Port ConnectionTime
---------- ----------   ------------- ---- --------------
Successful somehost.com 127.0.0.1     80  10.3 ms

```
### EXAMPLE
```
PS C:\> "www.google.com","www.microsoft.com" | Test-TCPPort -Port 80,443

Connection RemoteHost        RemoteAddress  Port ConnectionTime                                                         
---------- ----------        -------------  ---- --------------                                                         
Successful www.google.com    216.58.199.36  80   57.7 ms                                                                
Successful www.google.com    216.58.199.36  443  56.6 ms                                                                
Successful www.microsoft.com 23.194.133.122 80   9.8 ms
Successful www.microsoft.com 23.194.133.122 443  9.9 ms

```
### EXAMPLE
```
PS C:\> Connect-TCPPort somehost.com -80 -Timeout 2

Connection RemoteHost   RemoteAddress Port ConnectionTime
---------- ----------   ------------- ---- --------------
Successful somehost.com 127.0.0.1     80  10.3 ms

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
