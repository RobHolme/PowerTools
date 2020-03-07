function Test-SQLDatabase
{
<#
.NOTES
Function Name   : Test-SQLDatabase
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (31/07/2016)   - Initial version.
                : 1.1 (04/10/2016) - Prompt for password as SecureString, instead of accepting plain test password as parameter
Requires        : PowerShell V2

.SYNOPSIS
Tests connectivity to MS SQL Database. Returns true or false. Ffor connection details use Connect-Database.
.DESCRIPTION
Tests connectivity to MS SQL Database. Supports SQL user authentication, or integrated Windows authentication.
.EXAMPLE
Test-Database -Server 127.0.0.1\SQLExpress -Database NorthWind -Username Northwin-User -Password P@ssword
.EXAMPLE
Test-Database -Server SQLServer01 -Database NorthWind -UseWindowsAuthentication
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
            $dbConnection.ConnectionString = "Data Source=$Server; uid=$Username; pwd=$plainTextPassword; Database=$Database;Integrated Security=False"
            $authentication = "SQL ($Username)"
        }
        else {
            # create the connection string, use logged on users credentials for authentication
            $dbConnection.ConnectionString = "Data Source=$Server; Database=$Database;Integrated Security=True;"
            $authentication = "Windows ($env:USERNAME)"
        }
        try {
            $dbConnection.Open()
            return $true
        }
        # exceptions will be raised if the database connection failed.
        catch {
            return $false
        }
        Finally{
            # close the database connection
            $dbConnection.Close()
        }
    }
}


