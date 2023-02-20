# PowerTools ReadMe
A module containing a random collection of functions that I use occasionally. These originated as separate scripts but were merged into a module for transportability. May change over time as infrequently used functions are removed.    
 - __Export-Credential__: Export username and password to file as a secure string. Supports Windows Powershell only, deprecated in favour of the cross platform Microsoft.PowerShell.SecretManagement Module.
 - __Import-Credential__: Import username and password from file exported by Export-Credential. Supports Windows Powershell only, deprecated in favour of the cross platform Microsoft.PowerShell.SecretManagement Module.           
 - __Get-FolderSize__: Graphically display the the size of each subfolder within a specified directory.    
 - __Get-NetworkLatency__: Report network latency over sample period. Optionally display the results as a chart.
 - __Get-SMBShareCapacity__: Display the current capacity used by a SMB share.
 - __Get-SQLInstance__: Query the MS-SQL Browser to retrieve SQL Instance details"    
 - __Get-TLSCertificate__: Display the TLS certificate associated with a TCP interface. 
 - __Start-TCPListener__: Start a TCP listener on a nominated port. Used for connectivity testing.       
 - __Test-SQLDatabase__: Test a connection to a MS-SQL Server database.        
 - __Test-TCPPort__: Tests connectivity to a remote TCP port. Based on Test-NetConnection, but implements shorter (configurable) connection timeouts and removes ICMP connectivity tests if the TCP connection fails (intended to be faster than Test-NetConnection when testing large number of hosts).            



---

## Export-Credential
### DESCRIPTION
Exports a password to a file (as a secure string), may also include username and associated meta data. The password is encrypted (other items such as username are plain text), requiring the same user and host to be able to read the password. The exported password cannot be transported between hosts or users, it will fail to import. Encryption relies on Microsoft's Data Protection API (DPAPI), so this command supports Windows environments only.

Use Import-Password to return the PS Credential object from file.

__As this function only supports PowerShell on Windows, it is recommended to use the cross platform Microsoft.PowerShell.SecretManagement Module instead of this function.__

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

## Import-Credential
### DESCRIPTION
Import credentials previously saved by the Export-Credential command. Credentials must be imported by the same user, and on the same workstation as they were exported from (exported credentials are not portable). Decryption relies on Microsoft's Data Protection API (DPAPI), so this command supports Windows environments only.

__As this function only supports PowerShell on Windows, it is recommended to use the cross platform Microsoft.PowerShell.SecretManagement Module instead of this function.__
### SYNTAX
```PowerShell
Import-Credential [-Path] <String> [<CommonParameters>]
```
### PARAMETERS
```-Path <String>``` The full path and filename of the file to import the credentials from.

### EXAMPLE
```
PS > $Cred = Import-Credential -Path c:\temp\credential.xml

     $Cred.Username  # this is the domain\username
     $Cred.GetNetworkCredential().Password  # this is the plain text Password
```
---

## Get-FolderSize
### DESCRIPTION
Return the size of each subfolder within a specified directory. Include a total size which include files within the root of the folder. Percentage values are rounded so are only approximate. Same applies to small sizes using a large size unit - may be rounded to 0. 
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
## Get-NetworkLatency
### DESCRIPTION
Report the latency to a remote host. Define the number and frequency of ICMP connections to report on. Display min, max, and average latency results. Optionally save the results to a chart. e.g:

![Syntax highlighting](https://github.com/RobHolme/PowerTools/raw/master/images/latency.png)

### SYNTAX
```Powershell
Get-NetworkLatency [-Hostname] <String[]> [[-Count] <Int32>] [[-Interval] <Int32>] [[-ShowAllResults]] [[-GraphResult] <String>] [<CommonParameters>]
```
### PARAMETERS
```-Hostname <String[]>``` The Hostname or IP address of the host to connect to. Supply an array of hosts to test multiple hosts.

```-Count <Int32>``` The number of ICMP connection tests to perform.

```-Interval <Int32>``` The interval in seconds between tests. If the interval is less than 4 secs, the ICMP timeout will be set to match the interval (timeout remains at 4 secs for larger intervals).

```-ShowAllResults```

```-GraphResult <String>```

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
## Get-SQLInstance
### DESCRIPTION
Query the MS-SQL browser to retrieve details of the SQL Instances on a server

### SYNTAX
```PowerShell
Get-SQLInstance [-ComputerName] <String[]> [[-Timeout] <Int32>] [<CommonParameters>]
```
### PARAMETERS
```-ComputerName <String[]>``` The hostname or IP address of the MS-SQL server. Provide a list of server names to query multiple servers. 

```-Timeout <Int32>``` The time to wait (in seconds) for a response from the SQL Server Browser.
### EXAMPLE
```
Get-SQLInstance -ComputerName sqlsvr01

Hostname Computername SQLInstance        Version     IsClustered TCPPort
-------- ------------ -----------        -------     ----------- -------
sqlsvr01 SQLSVR01     SQLSVR01\SQLTEST   13.0.1601.5 False       51143
sqlsvr01 SQLSVR01     SQLSVR01\INSTANCE2 13.0.1601.5 False       51129
```

---
## Get-TLSCertificate
### DESCRIPTION
Retrieve TLS (SSL) certificate, display properties or export to .cer file. Default view contains more details, pipe to format-table to use a condensed view that only shows certificate subject CN, expiry date, and validity. The condensed view is more suited for tables of multiple certificates, while the default list view is more suited single or few certificates (but is more detailed).

The remote host does not need to be a web server, it should return the certificate of any TLS protected TCP service - such as LDAPS.

### SYNTAX
```PowerShell
 Get-TLSCertificate [-Hostname] <String> [[-Port] <Int32>] [[-SNIname] <String>] [[-ExportFile] <String>]
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
PS> Get-TLSCertificate -Hostname www.example.com
```
### EXAMPLE
Some websites may host multiple namespaces. Use SNIName to retrieve cert specific to a site name.
```
PS> Get-TLSCertificate -Hostname www.example.com -SNIName api.example.com
```
### EXAMPLE
Get LDAPS cert form a domain controller DC01
```
PS> Get-TLSCertificate -Hostname DC01 -port 636
```
### EXAMPLE
export certificate to c:\temp\CertExport.cer
```
PS> Get-TLSCertificate -Hostname www.example.com -ExportFile c:\temp\CertExport.cer
```
### EXAMPLE
pipe results to a table (condensed view)
```
PS> "google.com","microsoft.com","apple.com" | Get-TLSCertificate | ft

Hostname      CN                          Verified Expires
--------      --                          -------- -------
google.com    CN=*.google.com             True     15/11/2021 9:36:26 AM
microsoft.com CN=*.oneroute.microsoft.com True     30/06/2022 5:35:12 AM
apple.com     CN=images.apple.com         True     9/12/2021 11:21:27 PM
```
---

## Start-TCPListener
### DESCRIPTION
Starts a TCP listener. The listener will stop once a connection has been made from a client. By default the port will be closed after the TCP handshake is completed. If the -WaitForData parameter is supplied the command will wait unit the client closes the connection instead.
### SYNTAX
```PowerShell
Start-TCPListener [-Port] <int> [[-WaitForData]] [<CommonParameters>]
```
### PARAMETERS
```-Port <int>``` The TCP port number to listen on. The port must be available.

```-WaitForData [<SwitchParameter>]``` Wait for the client to send data, and wait for the client to close the connection. Without this parameter the connection is closed as soon as the TCP handshake is completed.

### EXAMPLE
```
PS> Start-TCPListener -Port 5000

Status                RemoteHost RemotePort
------                ---------- ----------
Connection Successful 127.0.0.1       50298
```
---

## Test-SQLDatabase
### DESCRIPTION
Tests logon connectivity to MS-SQL Database. Supports SQL user authentication, or integrated Windows authentication. Returns connections details (connection status, time to connect) on success or failure. 
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
Tests connectivity to a TCP port on a remote host. If successful, the time to connect is displayed with the endpoint details. Based on Test-NetConnection, but items such as ICMP checks are removed, and a shorter default timeout used to speed up tests of a large number of hosts/ports. Failed connections return quicker than Test-NetConnection. Another difference is this will show the result for all IP addresses that hostname resolves to, while Test-NetConnection only shows the first IP address to successfully respond.

Accepts an array of hosts to check via the pipeline (See examples). An array or range of ports can also be provided by the -Port parameter.

### SYNTAX
```PowerShell
Test-TCPPort [-Hostname] <String> [-Port] <Int32[]> [[-Timeout] <Int32>] [<CommonParameters>]
```
### PARAMETERS
```-Hostname <string>``` The name or IP address of the remote host to connect to. Accepts only a single hostname, but an array of hostnames can be piped to the command. 

```-Port <Int32[]>``` The port number on the remote host to connect to. Accepts a  single port, an array of ports, or a range of ports to test per host.

```-Timeout <Int32>``` The TCP connection timeout in seconds. Defaults to 5 seconds. System TCP timeout (20 secs?) will still apply if the timeout supplied exceeds the  system timeout. 
### EXAMPLE
```
PS C:\> Connect-TCPPort somehost.com -Port 80

Connection RemoteHost   RemoteAddress Port ConnectionTime
---------- ----------   ------------- ---- --------------
Successful somehost.com 127.0.0.1     80  10.3 ms

```
### EXAMPLE
Test ports 80 and 443 for www.google.com and www.microsoft.com. Use pipleline to test multiple hosts. 
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
Use a short timeout (2 seconds).
```
PS C:\> Connect-TCPPort somehost.com -Port 80 -Timeout 2

Connection RemoteHost   RemoteAddress Port ConnectionTime
---------- ----------   ------------- ---- --------------
Successful somehost.com 127.0.0.1     80   10.3 ms

```

### EXAMPLE
test a range of ports from 17190 to 17198
```
PS C:\>  Test-TCPPort samplehost -Port (17190..17198)

Connection RemoteHost RemoteAddress Port  ConnectionTime
---------- ---------- ------------- ----  --------------
Failed     samplehost  10.0.0.36   17190 0 ms
Failed     samplehost  10.0.0.36   17191 0 ms
Successful samplehost  10.0.0.36   17192 2.7 ms
Failed     samplehost  10.0.0.36   17193 0 ms
Failed     samplehost  10.0.0.36   17194 0 ms
Failed     samplehost  10.0.0.36   17195 0 ms
Successful samplehost  10.0.0.36   17196 2.6 ms
Successful samplehost  10.0.0.36   17197 2.8 ms
Successful samplehost  10.0.0.36   17198 2.8 ms
```