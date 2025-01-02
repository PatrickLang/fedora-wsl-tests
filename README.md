# End to end tests for Fedora in WSL

This is a simple set of end to end tests that aim to:

- Install a Fedora build using a .tar.xz or .wsl file
- Verify the user was set up as expected
- Test some basic functionality (sudo, dnf)

## Running the tests

```
Set-ExecutionPolicy -scope Process -ExecutionPolicy bypass
Invoke-Pester -Script .\test-fedora-wsl.ps1 -OutputFormat NUnitXml -OutputFile results.xml
```

Here's an example run from a system that already had WSL installed:

```
PS C:\Users\patri\Source\fedora-wsl-tests> wsl --version
WSL version: 2.3.26.0
Kernel version: 5.15.167.4-1
WSLg version: 1.0.65
MSRDC version: 1.2.5620
Direct3D version: 1.611.1-81528511
DXCore version: 10.0.26100.1-240331-1435.ge-release
Windows version: 10.0.22631.4602

PS C:\Users\patri\Source\fedora-wsl-tests> Set-ExecutionPolicy -scope Process -ExecutionPolicy bypass
PS C:\Users\patri\Source\fedora-wsl-tests> Invoke-Pester -Script .\test-fedora-wsl.ps1 -OutputFormat NUnitXml -OutputFile results.xml





WSL is old
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  100M  100  100M    0     0  12.9M      0  0:00:07  0:00:07 --:--:-- 20.3M
Installing Fedora_c15c5e5 in C:\Users\patri\Source\fedora-wsl-tests\Fedora_c15c5e5
Import in progress, this may take a few minutes.
The operation completed successfully.
Running oobe.sh
Please create a default UNIX user account. The username does not need to match your Windows username.
For more information visit: https://aka.ms/wslusers
Describing Default user was created correctly
 [+] uid is not 0 36.03s
 [+] username is not root 1.39s
 [+] should be in group wheel 1.14s
Describing Sudo is configured correctly
 [+] Can run sudo to run a command as root 1.6s
Unregistering.
The operation completed successfully.
Tests completed in 40.16s
Passed: 4 Failed: 0 Skipped: 0 Pending: 0 Inconclusive: 0
```


## Contributing

This script was written for the least-common-denominator of Windows 10 10.0.22631 and WSL 2.3.26.0, or higher.

It depends on the [pester](https://pester.dev) framework for organizing test cases and assertions, and it is capable of producing NUnit-style output. Windows 10 shipped with Pester 3.4.0 built-in so the test cases have been written to use that version instead of the latest. The assertions are much more limited than the current version, so look at the [Should-v3](https://github.com/pester/Pester/wiki/Should-v3) page instead to see what is supported.
