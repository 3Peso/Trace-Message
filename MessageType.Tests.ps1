Import-Module .\Tracing.psm1 -Force

Describe "MessageType" {
    InModuleScope Tracing {

        It "should be initialized" {
            [MessageType] | Should Not Be $null
        }

        It "should contain [Type]" -Test {
            param ([MessageType]$messageType)

            Write-Host "`tmessageType: $messageType"

            $messageType | Should Not Be $null
        } -TestCases @( 
            @{ messageType=[MessageType]::Message }
            @{ messageType=[MessageType]::Warning }
            @{ messageType=[MessageType]::Error }
            @{ messageType=[MessageType]::ActionError }
            @{ messageType=[MessageType]::Critical }
            @{ messageType=[MessageType]::Action }
            @{ messageType=[MessageType]::MultiStart }
            @{ messageType=[MessageType]::MultiEnd }
            @{ messageType=[MessageType]::Success }
            @{ messageType=[MessageType]::ActionSuccess }
            @{ messageType=[MessageType]::ActionProgress }
            @{ messageType=[MessageType]::ActionWarning }
            @{ messageType=[MessageType]::Unformatted } )
    }

    It "should contain 13 message types" {
        [MessageType].GetEnumNames().Count | Should Be 13
    }
}