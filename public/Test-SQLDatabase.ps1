function Test-SQLDatabase
{
<#
.NOTES
Function Name   : Test-Database
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (31/07/2016) - Initial version.
                : 1.1 (04/10/2016) - Prompt for password as SecureString, instead of accepting plain test password as parameter
Requires        : PowerShell V2

.SYNOPSIS
Tests connectivity to MS SQL Database. Reports connection details, then closes.
.DESCRIPTION
Tests connectivity to MS SQL Database. Supports SQL user authentication, or integrated Windows authentication.
.EXAMPLE
Connect-Database -Server 127.0.0.1\SQLExpress -Database NorthWind -Username Northwind -User -Password P@ssword
.EXAMPLE
Connect-Database -Server SQLServer01 -Database NorthWind -UseWindowsAuthentication
.PARAMETER Server
The Hostname or IP address of the SQL server to connect to. If connecting to a named instance, include the instance name e.g. server\instance
.PARAMETER Database
The name of the database to connect to
.PARAMETER Username
The SQL user account used to authenticate to the database
.PARAMETER UseWindowsAuthentication
Use the current logged on user's credentials to authenticate using Windows authentication
#>
    [CmdletBinding(DefaultParametersetName="WindowsAuth")]
    param(
        [Parameter(
            Position=0,
            Mandatory=$True,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$true)]
            [string] $Server,

        [Parameter(
            Position=1,
            Mandatory=$True)]
            [string] $Database,

        [Parameter(
            Position=2,
            Mandatory=$True,
            ParameterSetName="SQLAuth")]
            [string] $Username,

        [Parameter(
            Position=3,
            Mandatory=$False,
            ParameterSetName="SQLAuth")]
            [Security.SecureString] $Password,

        [Parameter(
            Position=2,
            Mandatory=$False,
            ParameterSetName="WindowsAuth")]
            [switch] $UseWindowsAuthentication
    )

    # connect to the database, then immediately close the connection. If an exception occurs it indicates the conneciton was not successful.
    process {
        $dbConnection = New-Object System.Data.SqlClient.SqlConnection
        if ($Username) {
            # prompt for the password if not supplied as a parameter (as a securestring)
            if ($Password.Length -lt 1) {
                $Password = Read-Host -Prompt "Enter password for the $Username SQL account" -AsSecureString
            }
            # get the plain text password
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            $plainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            # create the connection string using SQL user authentication
            $dbConnection.ConnectionString = "Data Source=$Server; uid=$Username; pwd=$plainTextPassword; Database=$Database;Integrated Security=False;MultiSubnetFailover=True"
            $authentication = "SQL ($Username)"
        }
        else {
            # create the connection string, use logged on users credentials for authentication
            $dbConnection.ConnectionString = "Data Source=$Server; Database=$Database;Integrated Security=True;MultiSubnetFailover=True"
            $authentication = "Windows ($env:USERDOMAIN\$env:USERNAME)"
        }
        try {
			$connectionTime = measure-command {$dbConnection.Open()}
			[PSCustomObject]@{
				PSTypeName     = "Powertools.TestDatabase.Result"
                Connection = "Successful"
                ElapsedTime = $connectionTime.TotalSeconds
                Server = $Server
                Database = $Database
				User = $authentication
			}
        }
        # exceptions will be raised if the database connection failed.
        catch {
			Write-Debug "Open database connection threw exception: $($_.Exception.Message)"
            [PSCustomObject]@{
				PSTypeName     = "Powertools.TestDatabase.Result"
                Connection = "Failed"
                ElapsedTime = $connectionTime.TotalSeconds
                Server = $Server
                Database = $Database
				User = $authentication
			}
        }
        Finally{
            # close the database connection
            $dbConnection.Close()
        }
    }
}


