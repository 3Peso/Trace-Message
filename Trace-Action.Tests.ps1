Import-Module Pester

Import-Module .\Tracing.psm1 -Force

Describe "Trace-Action" {
    InModuleScope Tracing {

        $expectedMessage = "Trace-Action_Tests_#1"
        Context "Successful call" {
            Mock Trace-Message { }
            Mock Get-FormattedMessage { }

            It "should call Trace-Message exaclty once with message '$expectedMessage ... '" {
                Trace-Action $expectedMessage -action { }

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "done" } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 0 -Scope It
            }

            $exceptedResult = $true
            It "should execute script block without exception returning '$exceptedResult'" {
                Trace-Action $expectedMessage -action { return $exceptedResult } | Should Be $true

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "done" } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 0 -Scope It
            }

            $expectedSuccessIndicator = "success"
            It "should use success indicator '$expectedSuccessIndicator'" {
                Trace-Action $expectedMessage -action {} -successIndicator $expectedSuccessIndicator

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq $expectedSuccessIndicator } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 0 -Scope It
            }

            $expectedSuccessIndicator = "the success"
            It "should use success indicator '$expectedSuccessIndicator'" {
                Trace-Action $expectedMessage -action { return $expectedSuccessIndicator } -useActionResultAsIndicator

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq $expectedSuccessIndicator } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 0 -Scope It
            }
        } 
        
        $expectedMessage = "Trace-Action_Tests_#2"
        Context "Failed call" {
            Mock Trace-Message { }
            Mock Get-FormattedMessage { }

            It "should call Trace-Message exaclty once with message '$expectedMessage ... '" {
                Trace-Action $expectedMessage -action { throw "Fail" }

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "failure" } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 1 -Scope It
            }

            $expectedFailureIndicator = "error"
            $expectedErrorMessage = "Error Message"
            It "should use failure indicator '$expectedFailureIndicator'" {
                Trace-Action $expectedMessage -action { throw $expectedErrorMessage } -failureIndicator $expectedFailureIndicator

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq "$expectedMessage ... " } -Scope It
                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq $expectedFailureIndicator } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 1 -Scope It
            }

            $expectedFailureIndicator = "error"
            It "should throw an error with stopOnError switch set" {
                { Trace-Action $expectedMessage -action { throw $expectedFailureIndicator } -stopOnError }| Should Throw

                Assert-MockCalled Get-FormattedMessage -Exactly 0 -Scope It -ParameterFilter { $message -ceq $expectedFailureIndicator }
            }

            $expectedErrorMessage = "Error Message"
            It "should call Trace-Message with error message '$expectedErrorMessage'" {
                Trace-Action $expectedMessage -action { throw $expectedErrorMessage }

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $message -ceq $expectedErrorMessage } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 1 -Scope It
            }

            $expectedErrorMessage = "Error Message"
            $expectedMessageType = [MessageType]::Error
            It "should call Trace-Message with message type '$expectedMessageType'" {
                Trace-Action $expectedMessage -action { throw $expectedErrorMessage }

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $messageType -ceq $expectedMessageType } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 1 -Scope It
            }

            $expectedErrorMessage = "Error Message"
            $expectedMessageType = [MessageType]::Warning
            It "should call Trace-Message with message type '$expectedMessageType'" {
                Trace-Action $expectedMessage -action { throw $expectedErrorMessage } -treatFailureAsWarning

                Assert-MockCalled Trace-Message -Exactly 1 -ParameterFilter { $messageType -ceq $expectedMessageType } -Scope It
                Assert-MockCalled Get-FormattedMessage -Exactly 1 -Scope It
            }
        }                        
    }
}