# PowerTools ReadMe
A module containing a random collection of functions that I use occasionally. These originated as separate scripts but were merged into a module for transportability.    
 - Export-Credential  
 - Get-FolderSize     
 - Get-SMBShareCapacity    
 - Get-SSLCertificate 
 - Import-Credential           
 - Start-TCPListener       
 - Test-SQLDatabase        
 - Test-TCPPort            



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
## Get-FolderSize
### DESCRIPTION
Return the size of each subfolder within a specified directory. Include a total size which include files within the root of the folder. Percentage values are rounded so are only approximate. Sample applies to small sizes using a large size unit - may be rounded to 0. 
### SYNTAX
```PowerShell
Get-FolderSize [[-Path] <Object>] [[-Unit] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```
### PARAMETERS
```-Path <string>``` The Path of the folder to report on. If not provided, the current folder will be used.

```-Unit <string>``` The size unit to use in results. Must be one of KB, MB, GB, or TB. Defaults to MB if value not supplied. 

### EXAMPLE
```
# get the size of 'H:\git repos\PowerTools\', sizes reported in KB
PS> Get-FolderSize 'H:\git repos\PowerTools\' -Unit KB

Path                            Files Size(KB) Graph                                          Percent
----                            ----- -------- -----                                          -------
H:\git repos\PowerTools\private     1     3.11                                                0.8%
H:\git repos\PowerTools\public     14    54.07 ■■■■■■■■                                       13.4%
H:\git repos\PowerTools\.git       90   311.02 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 77.2%
<Total>                           111   402.97
```
### EXAMPLE
```
# get the size of the current folder, defaulting to report sizes in MB
PS> Get-FolderSize

Path                                           Files Size(MB) Graph                                         Percent
----                                           ----- -------- -----                                         -------
C:\Program Files\Common Files\Services             1        0                                               0%
C:\Program Files\Common Files\DESIGNER             1     0.02                                               0%
C:\Program Files\Common Files\System              58    10.05 ■                                             1.4%
C:\Program Files\Common Files\microsoft shared   296   157.85 ■■■■■■■■■■■■■■                                22.7%
C:\Program Files\Common Files\Adobe              172      526 ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 75.8%
<Total>                                          528   693.93
```

---


---

---
## Get-SMShareCapacity
### DESCRIPTION
Return the free disk space, and total disk space for a SMB share. Free space available will include any quota limits applied to the user running the command. The user must have rights at the share level (folder rights not needed).

### SYNTAX
```PowerShell
Get-SMBShareCapacity [-UNCPath] <String> [[-Unit] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```
### PARAMETERS
```-UNCPath <String>``` The path to the SMB share in UNC format. If a folder names is included in the path, the properties of the parent share will be returned (i.e. folder paths ignored if supplied)  
```-Unit <String>``` The unit to format the free space and total space properties. Must be one of "KB", "MB", "GB", "TB". Defaults to "GB" if not supplied. 
### EXAMPLE
```
Get-SMBShareCapacity \\nas\homedrives

FreeSpace  TotalSpace  PercentFree Share
---------  ----------  ----------- -----
5526.37 GB 10717.44 GB 51.56%      \\nas\homedrives\
```

### EXAMPLE
```
"\\nas\homedrives","\\127.0.0.1\c$" | Get-SMBShareCapacity

Share             FreeSpace  TotalSpace  PercentFree
-----             ---------  ----------  -----------
\\nas\homedrives\ 5526.37 GB 10717.44 GB 51.56%      
\\127.0.0.1\c$\   714.78 GB  930.9 GB    76.78% 
```

---
## Get-SSLCertificate
### DESCRIPTION
Retrieve SSL certificate, display properties or export to .cer file. Default view contains more details, pipe to format-table to use a condensed view that only shows certificate subject CN, expiry date, and validity. The condensed view is more suited for tables of multiple certificates, while the default list view is more suited single or few certificates (but is more detailed).

### SYNTAX
```PowerShell
 Get-SSLCertificate [-Hostname] <String> [[-Port] <Int32>] [[-SNIname] <String>] [[-ExportFile] <String>]
    [<CommonParameters>]
```
### PARAMETERS
```-Hostname <string>``` The remote host to retrieve the certificate from. 

```-Port <int>``` The TCP port number of the remote site. Optional, will default to 443 TCP if omitted.

```-SNIname <string>``` Optionally provide a SNI (Server Name Indication) name. Where a single site supports multiple certs, SNI name identifies the cert requested.

```-ExportFile <string>``` Export the certificate to a base64 encoded X.509 certificate file (.CER).
### EXAMPLE
```
# get the certificate from www.example.com (default to port 443)
PS> Get-SSLCertificate -Hostname www.example.com
```
### EXAMPLE
```
PS> Get-SSLCertificate -Hostname www.example.com -SNIName api.example.com
```
### EXAMPLE
```
# get LDAPS cert form a domain controller
PS> Get-SSLCertificate -Hostname DC01 -port 636
```
### EXAMPLE
```
# export certificate to c:\temp\CertExport.cer
PS> Get-SSLCertificate -Hostname www.example.com -ExportFile c:\temp\CertExport.cer
```
### EXAMPLE
```
# pipe results to a table (condensed view)
PS> "google.com","microsoft.com","apple.com" | Get-SSLCertificate | ft

Hostname      CN                          Verified Expires
--------      --                          -------- -------
google.com    CN=*.google.com             True     15/11/2021 9:36:26 AM
microsoft.com CN=*.oneroute.microsoft.com True     30/06/2022 5:35:12 AM
apple.com     CN=images.apple.com         True     9/12/2021 11:21:27 PM
```

---
## Test-SQLDatabase
### DESCRIPTION
Tests logon connectivity to MS SQL Database. Supports SQL user authentication, or integrated Windows authentication. Returns connections details (connection status, time to connect) on success or failure. 
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
