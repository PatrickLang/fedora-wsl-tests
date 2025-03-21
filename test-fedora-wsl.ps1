param(
    [String]$commit = 'f42beta',
    [String]$url = 'https://download.fedoraproject.org/pub/fedora/linux/releases/test/42_Beta/Container/x86_64/images/Fedora-WSL-Base-42_Beta-1.4.x86_64.tar.xz'
)


# wsl.exe always outputs unicode without BOM, which the console can display,
# but PowerShell won't properly redirect into strings if the console is set to another encoding
$previousEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::Unicode

# TODO: move these to script parameters

# Install Parameters
$distroName = "Fedora_$($commit)"
# Globals
$wslUser = 'patrick'
$skipCleanup = $True

# Versions prior to 2.4.4 are "old" and require different setup steps and invocation than
# 2.4.4+ which are "new"
# See: https://fedoraproject.org/wiki/Changes/FedoraWSL
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
        [string]$cmdLine,
        [bool]$setUser = $True
    )

    $outFile = (New-TemporaryFile).FullName
    $errFile = (New-TemporaryFile).FullName
    
    $argList = '-d', $distroName
    if (($wslVersion -eq [WslVersions]::old) -and ($setUser)) {
        $argList += "-u $($wslUser)"
    }
    $argList += '--', $cmdLine

    return Unwrap-Wsl -argList $argList
}

function Unwrap-Wsl {
    param(
        [array]$argList
    )

    $outFile = (New-TemporaryFile).FullName
    $errFile = (New-TemporaryFile).FullName

    try {
        # Note - if a process in WSL is waiting on stdin, this will hang the test. Don't do that.
        $proc = Start-Process -NoNewWindow `
                    -FilePath wsl.exe `
                    -ArgumentList $argList `
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
            throw "wsl.exe $argList returned exit code: $($proc.ExitCode)"
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
    if (Test-Path $filename) {
        Write-Host "Using existing file $($filename) and skipping download"
    } else {
        Write-Host "Downloading $($filename)"
        curl.exe -Lo $filename $url
    }
    return Get-Item $filename
}

function Install-Distro {
[CmdletBinding()]
param (
    [Parameter()]
    [System.IO.FileInfo]
    $tarball
)
    
    switch ($wslVersion) {
        new {
            Write-Host "Installing $($distroName) from $($tarball.FullName)"
            wsl.exe --install --from-file $tarball.FullName --name $distroName
            # The `n are important here as PowerShell will always throw a CRLF at the end of the pipeline.
            # Manually adding the newline at the end allows a clean exit and the last CRLF is never parsed.
            Write-Output "$wslUser`nexit`n" | wsl.exe -d $distroName
        }
        old {
            $folder = New-Item -Force -ItemType Directory -Name $distroName
            Write-Host "Installing $($distroName) in $($folder.FullName)"
            wsl.exe --import $distroName $folder.FullName $tarball.FullName
            Write-Host "Running oobe.sh"
            wsl.exe -d $distroName -u root -- echo $wslUser `| /usr/libexec/wsl/oobe.sh
        }
        Default { throw "Install not supported on this version of Windows" }
    }
}

function Remove-Distro {
    if ((wsl.exe -l | Select-String $distroName).length -gt 0) {
        Write-Host "Removing existing distro $distroName"
        wsl.exe --unregister $distroName   
    }
}

function Test-Wsl {
    Describe "Default user was created correctly" {
        It "uid is not 0" {
            (Run-Wsl -cmdLine "id -u") | Should Be "1000"
        }
        It "username is not root" {
            $actualUser = Run-Wsl -cmdLine "id -un"
            $actualUser | Should Not Be "root"
            $actualUser | Should Be $wslUser
        }
        $idOutput = (Run-Wsl -cmdLine "id")
        It "should be in group wheel" {
            $idOutput | Should Match "wheel"
        }
    }

    Describe "Sudo is configured correctly" {
        It "Can run sudo to run a command as root" {
            Run-Wsl -cmdLine "sudo id -un" | Should Match 'root'
        }
    }

    # BUGBUG: Currently dnf is hanging when run from wsl.exe, but is fine if run interactively
    # dnf5.log shows the last line:
    # 2024-12-22T23:09:07+0000 [340] INFO RPM callback start trigger-install scriptlet "man-db-0:2.13.0-1.fc42.x86_64"
    Describe "sudo and dnf work" {
        It "Can run sudo -n dnf install ... without a password" {
            Run-Wsl -cmdLine "sudo -n dnf install --assumeyes pico"
        }
    }

    Describe "Can run a wayland app" {
        It "Can install foot" {
            Run-Wsl -cmdLine "sudo -n dnf install --assumeyes foot"
        }
        It "Can run foot" {
            # BUGBUG: Currently fails
            #  err: wayland.c:1552: failed to connect to wayland; no compositor running?
            Run-Wsl -cmdLine "foot sleep 5"
        }
    }
}


# main entrypoint
try {
    $wslVersion = Get-WslVersion
    Write-Host "WSL is $wslVersion"

    Write-Host "Cleaning up previous distro with same name if necessary..."
    Remove-Distro $tarball

    $tarball = Get-Build -url $url
    Install-Distro -tarball $tarball

    Test-Wsl
} finally {
    if (! $skipCleanup) {
        Remove-Distro $tarball
    }
}

[Console]::OutputEncoding = $previousEncoding