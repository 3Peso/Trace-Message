# Author: DreiPeso, 2013

$script:messageTemplate = "{0}][{1}]{2}{3}{4}"
$script:currentCulture = "de-DE"
Add-Type @"
    public enum MessageType
    {
        Message,
        Warning,
        Error,
        ActionError,
        Critical,
        Action,
        MultiStart,
        MultiEnd,
        Success,
        ActionSuccess,
        ActionProgress,
        ActionWarning,
        Unformatted
    }
"@
$script:logFile = [string]::Empty

$script:messageDecoration = @{
    "WriteOutput"=@{
        [MessageType]::Message={param($message) Write-Output $(Get-FormattedMessage -tag "    [INFO" -message $message) | Out-Host}
        [MessageType]::Warning={param($message) Write-Output $(Get-FormattedMessage -tag " [WARNING" -message $message) | Out-Host}
        [MessageType]::Error={param($message) Write-Output $(Get-FormattedMessage -tag "   [ERROR" -message $message) | Out-Host}
        [MessageType]::Critical={param($message) Write-Output $(Get-FormattedMessage -tag "[CRITICAL" -message $message) | Out-Host}
        [MessageType]::Action={param($message) Write-Output $(Get-FormattedMessage -tag "    [INFO" -message $message) | Out-Host}
        [MessageType]::ActionSuccess={param($message) Write-Output $(Get-FormattedMessage -tag " [SUCCESS" -message $message) | Out-Host}
        [MessageType]::ActionProgress={param($message) Write-Output $(Get-FormattedMessage -tag " [INFO" -message $message) | Out-Host}
        [MessageType]::ActionError={param($message) Write-Output $(Get-FormattedMessage -tag "   [ERROR" -message $message) | Out-Host}
        [MessageType]::ActionWarning={param($message) Write-Output $(Get-FormattedMessage -tag " [WARNING" -message $message) | Out-Host}
        [MessageType]::MultiStart={param($message) Write-Output $(Get-FormattedMessage -tag "   [START" -message $message) | Out-Host}
        [MessageType]::MultiEnd={param($message) Write-Output $(Get-FormattedMessage -tag "     [END" -message $message) | Out-Host}
        [MessageType]::Success={param($message) Write-Output $(Get-FormattedMessage -tag " [SUCCESS" -message $message) | Out-Host}
        [MessageType]::Unformatted={param($message) Write-Output $message}
    }
    "WriteHost"=@{
        [MessageType]::Message={param($message) Write-Host $(Get-FormattedMessage -tag "    [INFO" -message $message)}
        [MessageType]::Warning={param($message) Write-Host $(Get-FormattedMessage -tag " [WARNING" -message $message) -ForegroundColor Yellow}
        [MessageType]::Error={param($message) Write-Host $(Get-FormattedMessage -tag "   [ERROR" -message $message) -ForegroundColor Red}
        [MessageType]::Critical={param($message) Write-Host $(Get-FormattedMessage -tag "[CRITICAL" -message $message) -ForegroundColor Black -BackgroundColor Red}
        [MessageType]::Action={param($message) Write-Host $(Get-FormattedMessage -tag "    [INFO" -message $message) -NoNewline}
        [MessageType]::ActionSuccess={param($message) Write-Host $message -ForegroundColor Green}
        [MessageType]::ActionProgress={param($message) Write-Host $message -NoNewLine}
        [MessageType]::ActionError={param($message) Write-Host $message -ForegroundColor Red}
        [MessageType]::ActionWarning={param($message) Write-Host $message -ForegroundColor Yellow}
        [MessageType]::MultiStart={param($message) Write-Host $(Get-FormattedMessage -tag "   [START" -message $message) -ForegroundColor Black -BackgroundColor Green}
        [MessageType]::MultiEnd={param($message) Write-Host $(Get-FormattedMessage -tag "     [END" -message $message) -ForegroundColor Black -BackgroundColor Yellow}
        [MessageType]::Success={param($message) Write-Host $(Get-FormattedMessage -tag " [SUCCESS" -message $message) -ForegroundColor Green}
        [MessageType]::Unformatted={param($message) Write-Host $message}
    }
}

[int]$script:indention=0

$global:quietScript = $false
$global:unthrownExceptions = @()

#################################### Public Functions ####################################

function Trace-Message {
    param(
        [Parameter(Mandatory=$true)][string]$message,
        [Parameter(Mandatory=$false)][MessageType]$messageType
    )

    if($messageType -eq $null) {
        $messageType = [MessageType]::Message
    }

    if([string]::IsNullOrEmpty($global:output)) {
        $global:output = "WriteOutput"    
    }

    if(-not $global:quietScript) {
        Invoke-Command $($script:messageDecoration[$global:output][$messageType]) -ArgumentList $message
        #& $script:messageDecoration[$global:output][$messageType]
    }
}

function Trace-Action {
    param(
        [Parameter(Mandatory=$true)][string]$message,
        [Parameter(Mandatory=$true)][scriptblock]$action,
        [Parameter(Mandatory=$false)][switch]$stopOnError,
        [Parameter(Mandatory=$false)][switch]$useActionResultAsIndicator,
        [Parameter(Mandatory=$false)][string]$successIndicator,
        [Parameter(Mandatory=$false)][string]$failureIndicator,
        [Parameter(Mandatory=$false)][Hashtable]$colorLookup,
        [Parameter(Mandatory=$false)][switch]$treatFailureAsWarning
    )

    Trace-Message -message "$message ... " -messageType Action

    [string]$success = "done"
    if([String]::IsNullOrEmpty($successIndicator) -eq $false) {
        $success = $successIndicator
    }
    [string]$failure = "failure"
    if([string]::IsNullOrEmpty($failureIndicator) -eq $false) {
        $failure = $failureIndicator
    }

    try
    {
        $result = & $action
        if($useActionResultAsIndicator) { $success = $result }

        $color = "Green"
        if(($colorLookup -ne $null) -and ($colorLookup.ContainsKey($result))) {
            $color = $colorLookup[$result]
        }

        Trace-Message $success -messageType ActionSuccess
    }
    catch
    {
        [MessageType]$resultType = [MessageType]::ActionError
        [MessageType]$messageType = [MessageType]::Error
        if($treatFailureAsWarning.IsPresent) {$resultType = [MessageType]::ActionWarning; $messageType = [MessageType]::Warning}
        Trace-Message $failure -messageType $resultType
        Trace-Message -message "$($_.Exception.Message)" -messageType $messageType
        if($stopOnError) {
            throw
        } else {
            $global:unthrownExceptions += Get-FormattedMessage -message "$($_.Exception.Message)" -onlyTimestamp
        }
    }

    $result
}

function Trace-MultiStepAction {
    param(
        [Parameter(Mandatory=$true)][string]$message,
        [Parameter(Mandatory=$true)][scriptblock]$action,
        [Parameter(Mandatory=$false)][switch]$stopOnError,
        [Parameter(Mandatory=$false)][switch]$supressHeaderFooter      
    )
    
    if(-not $supressHeaderFooter.IsPresent) {
        Trace-Message -message $message -messageType MultiStart
    }

    try
    {
        $script:indention += 1    
        $result = & $action
    }
    catch
    {
        Trace-Message "Failed to finish action. $($_.Exception.Message)" -messageType Error           
        if($stopOnError) {    
            throw
        } else {
            $global:unthrownExceptions += Get-FormattedMessage -message "$($_.Exception.Message)" -onlyTimestamp
        }
    }
    finally
    {
        $script:indention -= 1
        
        if($script:indention -lt 0) {
            $script:indention = 0
            Trace-Message "Indention is smaller than zero." Critical
        }
        
        if(-not $supressHeaderFooter.IsPresent) {
            Trace-Message -message $message -messageType MultiEnd   
        }      
    }

    $result
}

function Trace-NameValueCollection {
    param(
        [Parameter(Mandatory=$true)]$nameValueCollection
    )

    Trace-MultiStepAction -message "Tracing Script Variables." -action { $nameValueCollection | % {
        Trace-Message -message "$($_.Name): '$($_.Value)'" -messageType Message
    }}
}

function Get-Excludes {
   @("?","args","ConsoleFileName","ExecutionContext","false","HOME","Host","input","MaximumAliasCount","MaximumDriveCount","MaximumErrorCount",
            "MaximumFunctionCount","MaximumVariableCount","MyInvocation","null","PID","PSBoundParameters","PSCommandPath","PSDebugContext",
            "PSHOME","PSScriptRoot","PSVersionTable","ShellId","true")
}

function Trace-HashTable {
    param(
        [Parameter(Mandatory=$true)]$hashTable
    )

    $hashTable.Keys | % {
        Trace-Message -message "$_ : '$($hashTable[$_])'" -messageType Message
        }
}

function Start-Tracefile {
    try
    {
        Get-LogFileName
        Start-Transcript -Path $script:logFile -Force -ea silentlycontinue
    }
    catch
    {
        Write-Output "Could not start log tracing in file '$script:logFile'." -ForegroundColor Yellow
    }

    [string]$script:startDate = Get-Date
    Trace-Message "----------------------------------------------------------" -messageType Unformatted 
    Trace-Message " Started on: $script:startDate" -messageType Unformatted 
    Trace-Message "----------------------------------------------------------" -messageType Unformatted
}

function Stop-Tracefile {
    [string]$script:endDate = Get-Date
    Trace-Message "----------------------------------------------------------" -messageType Unformatted 
    Trace-Message " Finished on: $script:endDate" -messageType Unformatted 
    Trace-Message "----------------------------------------------------------" -messageType Unformatted 
    
    try
    {        
        Stop-Transcript -ea silentlycontinue
        #Invoke-Item $script:logFile -ea silentlycontinue
    }
    catch
    {
        Write-Output "Could not stop log tracing."
    }
}

function Set-TraceMode {
    param(
        [Parameter(Mandatory=$true)][bool]$useHighlighting
    )

    if($useHighlighting -eq $true) {
        $global:output = "WriteHost"
    } else {
        $global:output = "WriteOutput"
    }
}

#################################### Helper Functions ####################################

function Get-FormattedMessage {
    param(
        [Parameter(Mandatory=$false)][string]$tag,
        [Parameter(Mandatory=$true)][string]$message,
        [Parameter(Mandatory=$false)][switch]$onlyTimestamp
    )

    [string]$formattedMessage = [string]::Empty

    $culture = New-Object System.Globalization.CultureInfo($script:currentCulture)
    if($onlyTimestamp.IsPresent) {
        $formattedMessage = "$(Get-Date -format ($culture.DateTimeFormat.LongTimePattern)) : $message"
    } else {
        $formattedMessage = [string]::Format($script:messageTemplate, $tag, $(Get-Date -format ($culture.DateTimeFormat.LongTimePattern)), "`t", $(Get-Indention), $message)
    }

    $formattedMessage
}

function Get-LogFileName
{
    $invocation = (Get-Variable MyInvocation -Scope 1).Value;
    if($Invocation.ScriptName)
    {
        $script:logFile = $Invocation.ScriptName;
    }
    else
    {
        $script:logFile = $invocation.PSCommandPath;
    }

    $script:logFile = $script:logFile.Replace([System.IO.Path]::GetFileName($script:logFile), `
        [System.IO.Path]::GetFilenameWithoutExtension($script:logFile))
    $script:logFile = "$script:logFile-$(Get-Date -Format yyyy-MM-dd_HH-mm).rtf"
}

function Get-Indention {
    [string]$indentionString = ""
    for($i=0; $i -lt $script:indention; $i++) {
        $indentionString += "| "
    }
    
    $indentionString
}

####################################     Exports     #####################################

Export-ModuleMember -Function Trace-Message
Export-ModuleMember -Function Trace-Action
Export-ModuleMember -Function Trace-MultiStepAction
Export-ModuleMember -Function Trace-NameValueCollection
Export-ModuleMember -Function Trace-HashTable
Export-ModuleMember -Function Get-Excludes
Export-ModuleMember -Function Start-Tracefile
Export-ModuleMember -Function Stop-Tracefile
Export-ModuleMember -Function Set-TraceMode
