# wsl.exe always outputs unicode without BOM, which the console can display,
# but PowerShell won't properly redirect into strings if the console is set to another encoding
$previousEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::Unicode

enum WslVersions {
    old
    new
}


function Get-WslVersion {
    $wslVersionOutput = wsl.exe --version
    $versionMatch = ($wslVersionOutput | Select-String -Pattern "WSL version: ([\d\.]*)")
    if (-not $versionMatch) {
        throw "WSL version not found"
    }
    $versionString = $versionMatch.Matches[0].Groups[1].Value
    Write-Debug "WSL version $versionString found"
    if ([version]$versionString -ge [version]'2.4.4.0') {
        return [WslVersions]::new
    }
    return [WslVersions]::old
}

function Run-Wsl {
    param(
        [string]$cmdLine
    )

    $outFile = (New-TemporaryFile).FullName
    $errFile = (New-TemporaryFile).FullName

    try {
        # BUG - if a process in WSL is waiting on stdin, this will hang the test
        $proc = Start-Process -NoNewWindow `
                    -FilePath wsl.exe `
                    -ArgumentList '-d', $Global:distroName, '--', $cmdLine `
                    -Wait `
                    -PassThru `
                    -RedirectStandardOutput $outFile `
                    -RedirectStandardInput $errFile
        if ((Get-Item $outFile).length -gt 0) {
            $out = (Get-Content $outFile).ToString()
        } elseif ((Get-Item $errFile).length -gt 0) {
            $out = (Get-Content $errFile).ToString()
        } else {
            $out = ""
        }
        if ($proc.ExitCode -ne 0) {
            throw "wsl.exe -- $cmdLine returned exit code: $($proc.ExitCode)"
        }
    } finally {
        Remove-Item $outFile
        Remove-Item $errFile
    }
    return $out
}

function Get-Build {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $url
    )
    $filename = $url | Split-Path -Leaf
    curl.exe -Lo $filename $url
    return $filename
}

function Test-Wsl {
    Describe "Default user was created correctly" {
        It "uid is not 0" {
            (Run-Wsl -cmdLine "id -u") | Should Be "1000"
        }
        It "username is not root" {
            (Run-Wsl -cmdLine "id -un") -eq "root" | Should Not Be "root"
        }
        $idOutput = (Run-Wsl -cmdLine "id")
        It "should be in group wheel" {
            $idOutput | Should Match "wheel"
        }
        It "should be in group sudo" {
            $idOutput | Should Match "sudo"
        }
    }

    Describe "Sudo is configured correctly" {
        It "Can run sudo -n dnf install ... without a password" {
            Run-Wsl -cmdLine "sudo -n dnf install --assumeyes fastfetch"
        }
    }
}


# main entrypoint
$wslVersion = Get-WslVersion
Write-Host "WSL is $wslVersion"

# TODO: move these to parameters
$Global:commit = "c15c5e5"
$Global:distroName = "Fedora_$($Global:commit)"
$url = 'https://artifacts.dev.testing-farm.io/34ef2b4c-77cb-46b2-95ea-6acfebba8f71/work-buildmne4pw0d/tmt/plans/wsl/build/execute/data/guest/default-0/tmt/tests/build-image-1/data/Fedora-WSL-Base-Rawhide.20241219.2217.x86_64.tar.xz'

Get-Build -url $url
# TODO: install, set globals for distro name

Test-Wsl
# TODO: cleanup WSL

[Console]::OutputEncoding = $previousEncoding