Import-Module Pester

Import-Module .\Tracing.psm1 -Force

Describe "Trace-Action" {
    InModuleScope Tracing {
        $script:expectedMessage = "Trace-Action_Tests_#1"
        Context "Successful call" {
            It "should call Trace-Message exaclty once with message '$expectedMessage ... '" {
                Mock Trace-Message { }
                Mock Get-FormattedMessage { }

                Trace-Action $expectedMessage -action { }
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "done" } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 0 -Scope It
            }

            It "should execute script block without exception returning '$expectedMessage'" {
                Mock Trace-Message { }
                Mock Get-FormattedMessage { }                
                Trace-Action $expectedMessage -action { return "$expectedMessage" } | Should -Be $true

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "done" } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 0 -Scope It
            }

            $script:expectedSuccessIndicator = "success"
            It "should use success indicator '$expectedSuccessIndicator'" {
                Mock Trace-Message { }
                Mock Get-FormattedMessage { }                
                Trace-Action $expectedMessage -action {} -successIndicator $expectedSuccessIndicator

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq $expectedSuccessIndicator } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 0 -Scope It
            }

            $script:expectedSuccessIndicator = "the success"
            It "should use success indicator '$expectedSuccessIndicator'" {
                Mock Trace-Message { }
                Mock Get-FormattedMessage { }                
                Trace-Action $expectedMessage -action { return $expectedSuccessIndicator } -useActionResultAsIndicator

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq $expectedSuccessIndicator } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 0 -Scope It
            }

       } 

        $script:expectedMessage = "Trace-Action_Tests_#2"
        Context "Failed call" {

            It "should call Trace-Message exaclty once with message '$expectedMessage ... '" {
                Mock Trace-Message { }
                Mock Get-FormattedMessage { }                
                Trace-Action $expectedMessage -action { throw "Fail" }

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "failure" } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 1 -Scope It
            }

            $script:expectedFailureIndicator = "error"
            $script:expectedErrorMessage = "Error Message"
            It "should use failure indicator '$expectedFailureIndicator'" {
                Mock Trace-Message { }
                Mock Get-FormattedMessage { }                
                Trace-Action $expectedMessage -action { throw $expectedErrorMessage } -failureIndicator $expectedFailureIndicator

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq $expectedFailureIndicator } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 1 -Scope It
            }

            $script:expectedFailureIndicator = "error"
            It "should throw an error with stopOnError switch set" {
                Mock Trace-Message { }
                Mock Get-FormattedMessage { }                
                { Trace-Action $expectedMessage -action { throw $expectedFailureIndicator } -stopOnError }| Should -Throw

                Assert-MockCalled Get-FormattedMessage -Exactly 0 -Scope It -ParameterFilter { $message -ceq $expectedFailureIndicator }
            }

            $script:expectedErrorMessage = "Error Message"
            It "should call Trace-Message with error message '$expectedErrorMessage'" {
                Mock Trace-Message { }
                Mock Get-FormattedMessage { }                
                Trace-Action $expectedMessage -action { throw $expectedErrorMessage }

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq $expectedErrorMessage } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 1 -Scope It
            }

            $script:expectedErrorMessage = "Error Message"
            $script:expectedMessageType = [MessageType]::Warning
            It "should call Trace-Message with message type '$expectedMessageType'" {
                Mock Trace-Message { }
                Mock Get-FormattedMessage { }                
                Trace-Action $expectedMessage -action { throw $expectedErrorMessage } -treatFailureAsWarning

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $messageType -ceq $expectedMessageType } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 1 -Scope It
            }
        }               
    }
}