# Trace-Message

Simple tracing library for PowerShell and Windows PowerShell.

The idea was that I wanted to be able to put a function call inside a function which would create some sort of tracing mechanism when the function I wanted to trace
started and when did it end. Also, the call hierachy should be visible.

## Usage

This module provides several cmdlets, which can help to trace your function calls. It also can produce log files by using `Start-Transcript` and `Stop-Transcript`
internally.

For writing messages, the module uses `Write-Host`, or alternatively `Write-Output`.

### Trace-Message

Simply traces a message with a timestamp at the beginning.

For example:

```
function Test {
    Trace-Message "This is a test" -messageType Critical
}
```

Calling `Test` from above would result in the following message:

```
...
[CRITICAL][16:03:13]	This is a test
...
```

### Trace-Action

If you would trace a single step action resulting in a simple "done" message at the end, you can use `Trace-Action`.

For example:

```
function OneStepAction {
    Trace-Action -message "This is a one step action" -action {
        Start-Sleep -Seconds 2
    }
}
```

Calling `OneStepAction` from above would result in a message like the following:

```
   ...
    [INFO][16:04:27]	This is a one step action ... done
   ...
```
Where the "done" would be in a new line, if you use `Write-Output`.

### Trace-MultiStepAction

If you want to trace one or more nested function calls, you can use the cmdlet `Trace-MultiStepAction`.

For example:

```
function OneStepAction {
    Trace-Action -message "This is a one step action" -action {
        Start-Sleep -Seconds 2
    }
}

function MultiStepOne {
    Trace-MultiStepAction -message "Multistep one" -action {
        Trace-Message "Something is going on." -messageType Warning
        Start-Sleep -Seconds 1
        MultistepTwo
    }
}

function MultistepTwo {
    Trace-MultiStepAction -message "Some actions will happen here" -action {
        OneStepAction
        OneStepAction
    }
}
```

Calling `MultistepOne` from above would result in the following output:

```
   [START][16:12:34]	Multistep one
 [WARNING][16:12:34]	| Something is going on.
   [START][16:12:35]	| Some actions will happen here
    [INFO][16:12:35]	| | This is a one step action ... done
    [INFO][16:12:37]	| | This is a one step action ... done
     [END][16:12:39]	| Some actions will happen here
     [END][16:12:39]	Multistep one
```

As you can see, not only the start and end of the calls is mentioned. Also, the call hierachy is been visualized.

### Start-Tracefile and Stop-Tracefile

You can log the message to a log file by calling `Start-Tracefile`. This will start tracing all the output messages to a file called like the script
file, in which you called the cmdlet. Messages will be stored inside a .rtf-file with a timestamp at the end.

For example if you have the following script file `test.ps1`:

```
Import-Module .\Tracing.psm1

function Test {
    Trace-Message "This is a test" -messageType Critical
}

Start-Tracefile

Test

Stop-Tracefile
```

And you would run it. This would result, for example, in the file `Test-2022-11-09_15-53.rtf` with the following content:

```
**********************
nStart der Windows PowerShell-Aufzeichnung
Startzeit: 20221109155346
Username: someuser
RunAs-User: someuser
Konfigurationsname: 
Computer: Computername (Microsoft Windows NT xxxxxxx)
Hostanwendung: C:\windows\System32\WindowsPowerShell\v1.0\powershell_ise.exe
Prozess-ID: 19728
PSVersion: 5.1.22621.608
PSEdition: Desktop
PSCompatibleVersions: 1.0, 2.0, 3.0, 4.0, 5.0, 5.1.22621.608
BuildVersion: 10.0.22621.608
CLRVersion: 4.0.30319.42000
WSManStackVersion: 3.0
PSRemotingProtocolVersion: 2.3
SerializationVersion: 1.1.0.1
**********************
Die Aufzeichnung wurde gestartet. Die Ausgabedatei ist "E:\Projekte\Tracing\Tests-2022-11-09_15-53.rtf".
----------------------------------------------------------
 Started on: 11/09/2022 15:53:46
----------------------------------------------------------
[CRITICAL][15:53:46]	This is a test
----------------------------------------------------------
 Finished on: 11/09/2022 15:53:46
----------------------------------------------------------
**********************
Ende der Windows PowerShell-Aufzeichnung
Endzeit: 20221109155346
**********************
```

As you can see, there is a lot of additional metadata stored inside. So, just using `Start-Transcript` and `Stop-Transcript` would not cut it.

### Set-TraceMode

Using this cmdlet you can control, if you use `Write-Host` or `Write-Output` by calling `Set-TraceMode`. If you run `Set-TraceMode -useHighlighting` 
`Write-Host` will be used, which will be set by default to use `Write-Output` the first time `Trace-Message` is been called. And `Trace-Message` will be 
called virtually by every other tracing cmdlet for writing messages. So, by default `Write-Output` will be used.

## Message Types

There are several message types defined in the script variable `$messageDecoration`. These types basically control who the message will be shown in the scripting
host window. For obviouse reasons, when you use `Write-Output`, you cannot expect different foreground or background colors.

I have included the message type definition here. So you can look them up yourself. Or, just look inside the module ;-)

```
...
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
...
```

## Final thoughts

I have written this little helper lib back in my earlier PowerShell days. There are things going on, I would not do so today. For example, using globals. O.O
So, please take that in mind. As always, don`t use code from a third party, which you don`t understand. Big "surprises" will happen ;-)
