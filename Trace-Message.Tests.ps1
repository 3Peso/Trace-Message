Import-Module Pester

Import-Module .\Tracing.psm1 -Force

Describe "Trace-Message" {
    InModuleScope Tracing {
        
        $expectedMessage = "Trace-Message_Tests_#1"
        $expectedTag = "    [INFO"
        $expectedOutput = 'WriteOutput'
        Context "No message type provided and no global output set" {
            Mock Get-FormattedMessage { }
            Mock Write-Output { }

            $global:output = $null

            It "should call Get-FormattedMessage and Write-Output exactly once" {
                Trace-Message $expectedMessage
                
                Assert-MockCalled Get-FormattedMessage -Exactly 1
                Assert-MockCalled Write-Output -Exactly 1
            }

            It "should use global output '$expectedOutput'" {
                Trace-Message $expectedMessage
                
                $global:output | Should BeExactly $expectedOutput
            }

            It "should call Get-FormattedMessage with expected message '$expectedMessage'" {
                Trace-Message $expectedMessage
                
                Assert-MockCalled Get-FormattedMessage -ParameterFilter { $message -ceq $expectedMessage }
            }

            It "should call Get-FormattedMessage with expected tag '$expectedTag'" {
                Trace-Message $expectedMessage
                
                Assert-MockCalled Get-FormattedMessage -ParameterFilter { $tag -ceq $expectedTag }
            }
        }

        $expectedMessage = "Trace-Message_Tests_#2"
        $expectedTag = " [WARNING"
        $expectedOutput = 'WriteHost'
        $expectedMessageType = [MessageType]::Warning
        Context "Message type 'Warning' provided and global output set to 'WriteHost'" {
            Mock Get-FormattedMessage { }
            Mock Write-Output { }

            $global:output = $expectedOutput

            It "should call Get-FormattedMessage and Write-Host exactly once" {
                Trace-Message $expectedMessage -messageType $expectedMessageType
                
                Assert-MockCalled Get-FormattedMessage -Exactly 1
                Assert-MockCalled Write-Host -Exactly 1
            } -Skip

            It "should use global output '$expectedOutput'" {
                Trace-Message $expectedMessage -messageType $expectedMessageType
                
                $global:output | Should BeExactly $expectedOutput
            }

            It "should call Get-FormattedMessage with expected message '$expectedMessage'" {
                Trace-Message $expectedMessage -messageType $expectedMessageType
                
                Assert-MockCalled Get-FormattedMessage -ParameterFilter { $message -ceq $expectedMessage }
            }

            It "should call Get-FormattedMessage with expected tag start '$expectedTag'" {
                Trace-Message $expectedMessage -messageType $expectedMessageType
                
                Assert-MockCalled Get-FormattedMessage -ParameterFilter { $tag -ceq $expectedTag }
            }
        }

        $expectedMessage = "Trace-Message_Tests_#3"
        Context "Message type '[MessageType]' provided and global output set to 'WriteOutput'" {
            Mock Get-FormattedMessage { }
            Mock Write-Output { }

            $global:output = 'WriteOutput'

            It "should call Get-FormattedMessage with expected tag" {
                param(
                    [string]$expectedTag,
                    [MessageType]$messageType
                )
                Write-Host "`texpectedTag: $expectedTag"
                Write-Host "`tmessageType: $messageType"

                Trace-Message $expectedMessage -messageType $messageType
                
                Assert-MockCalled Get-FormattedMessage -ParameterFilter { $tag -ceq $expectedTag }
            } -TestCases @(
                @{ messageType=[MessageType]::Message
                   expectedTag="    [INFO" }
                @{ messageType=[MessageType]::Warning
                   expectedTag=" [WARNING" }
                @{ messageType=[MessageType]::Error
                   expectedTag="   [ERROR" }
                @{ messageType=[MessageType]::ActionError
                   expectedTag="   [ERROR" }
                @{ messageType=[MessageType]::Critical
                   expectedTag="[CRITICAL" }
                @{ messageType=[MessageType]::Action
                   expectedTag="    [INFO" }
                @{ messageType=[MessageType]::MultiStart
                   expectedTag="   [START" }
                @{ messageType=[MessageType]::MultiEnd
                   expectedTag="     [END" }
                @{ messageType=[MessageType]::Success
                   expectedTag=" [SUCCESS" }
                @{ messageType=[MessageType]::ActionSuccess
                   expectedTag=" [SUCCESS" }
                @{ messageType=[MessageType]::ActionProgress
                   expectedTag=" [INFO" }
                @{ messageType=[MessageType]::ActionWarning
                   expectedTag=" [WARNING" }
            )
        }
    }  
}