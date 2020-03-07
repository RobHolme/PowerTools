# dot source private functions
$privateFunctions = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "..\private\PrivateFunctions.ps1"
. $privateFunctions

function Remove-WordMetadata {
    <#
.NOTES
Function Name   : Remove-WordMetadata
Author          : Rob Holme (rob@holme.com.au)
Version         : 1.0 (16/08/2016)
Requires        : PowerShell V2

.SYNOPSIS
Removes document properties for a MS Word Document
.DESCRIPTION
Removes all document properties for a MS Word Document, including templates, ink annotations, comments, custome properties, etc.
.EXAMPLE
Remove-WordMetadata -Path c:\test.doc
.PARAMETER Path
The name of the word document
.PARAMETER KeepTemplate
Leave the template attached to the document
.PARAMETER KeepInkAnnotations
Leave the template attached to the document
#>

    [CmdletBinding(DefaultParameterSetName = 'Path')]
    Param(
        [Parameter(
            Position = 0,
            Mandatory = $True,
            ParameterSetName = "Path",
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]] $Path,

        [Parameter(
            Position = 0,
            Mandatory = $True,
            ParameterSetName = "LiteralPath",
            ValueFromPipeline = $False,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Literal path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [string[]] $LiteralPath,

        [Parameter(
            Mandatory = $False)]
        [switch] $KeepTemplate,

        [Parameter(
            Mandatory = $False)]
        [switch] $KeepInkAnnotations,

        [Parameter(
            Mandatory = $False)]
        [switch] $KeepComments,

        [Parameter(
            Mandatory = $False)]
        [switch] $KeepRevisionInformation
    )

    begin {
        # warn and exit if using powershell core, only supported on Windows Powershell v2, v3, v4 and v5.x
        If ($IsCoreCLR) {
            $abortProcessing = $true
            write-warning "This function is not supported under PowerShell Core. This requires Windows PowerShell."
        }
        else {
            $abortProcessing = $false
        }
    }

    process {
        if (!$abortProcessing) {
           
            $paths = @()
            # check and expand wildcard paths
            if ($psCmdlet.ParameterSetName -eq 'Path') {
                $paths = ProcessPath $Path
            }
            # check and expand literal paths
            else {
                $paths = ProcessLiteralPath $Path
                
            }

            Add-Type -AssemblyName Microsoft.Office.Interop.Word
            $application = New-Object -ComObject word.application

            foreach ($aPath in $paths) {
                $document = $application.documents.open($aPath)
                $application.Visible = $false
                # suppress warnings to save when comments or ink annotations are present
                $application.Options.WarnBeforeSavingPrintingSendingMarkup = $false
                $WdRemoveDocType = "Microsoft.Office.Interop.Word.WdRemoveDocInfoType" -as [type]
                # remove individual properties from the document.
                Write-Verbose "Removing document properties from $aPath"
                #$document.RemoveDocumentInformation($WdRemoveDocType::wdRDIAll) # remove all properties - not used as I need to provide the option of retaining some properties
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIVersions)
                Write-Verbose "Version information removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIRemovePersonalInformation)
                Write-Verbose "Personal information removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIEmailHeader)
                Write-Verbose "Email header removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIRoutingSlip)
                Write-Verbose "Routing slip removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDISendForReview)
                Write-Verbose "Send for review removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIDocumentProperties)
                Write-Verbose "Document properties removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIDocumentServerProperties)
                Write-Verbose "Document Server properties removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIDocumentManagementPolicy)
                Write-Verbose "Document management policy removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIContentType)
                Write-Verbose "Content Type information removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIDocumentWorkspace)
                Write-Verbose "Document Workspace information removed"
                $document.RemoveDocumentInformation($WdRemoveDocType::wdRDITaskpaneWebExtensions)
                Write-Verbose "Task pane web extension removed"
                # preserve the document template if the -KeepTemplate switch is set
                if (!$KeepTemplate) {
                    $document.RemoveDocumentInformation($WdRemoveDocType::wdRDITemplate)
                    Write-Verbose "Document template removed"
                }
                # preserve ink annotations if the -KeepInkAnnotations switch is set
                if (!$KeepInkAnnotations) {
                    $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIInkAnnotations)
                    Write-Verbose "Ink Annotations removed"
                }
                # preserve comments if the -KeepComments is set
                if (!$KeepComments) {
                    $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIComments)
                    Write-Verbose "Comments removed"
                }
                # preserve revision information (change tracking) if the -KeepRevisionInformation switch is set
                if (!$KeepRevisionInformation) {
                    $document.RemoveDocumentInformation($WdRemoveDocType::wdRDIRevisions)
                    Write-Verbose "Revision information removed"
                }
                # if the document doesn't include task pan web extensions or document workspace information, an exception is thrown. Is so just continue.
                trap [system.exception] {
                    continue
                }
                # save and close the document, close down MS Word.
                $document.Save()
                $application.documents.close()
            }
            $application.quit()
        }
    }
}
