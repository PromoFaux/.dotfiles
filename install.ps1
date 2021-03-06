#Requires -RunAsAdministrator

function Write-Error([string]$message) {
    [Console]::ForegroundColor = 'red'
    [Console]::Error.WriteLine($message)
    [Console]::ResetColor()
}

function Write-Warn([string]$message) {
    [Console]::ForegroundColor = 'yellow'
    [Console]::Error.WriteLine($message)
    [Console]::ResetColor()
}

function CommandExists([string]$cmdName)
{
    $local:return = Get-Command $cmdName -ErrorAction SilentlyContinue
    return $local:return
}

# Sanity Check

if (-not [environment]::Is64BitOperatingSystem) {
    Write-Error "Only 64 bit Windows is supported"
    exit
}

#Kill these two if they're running
taskkill /f /im:gpg-agent.exe
taskkill /f /im:wsl-ssh-pageant.exe

#delete .gitconfig if it exists.
Remove-Item $env:USERPROFILE\.gitconfig -ErrorAction SilentlyContinue

$script:account = "promofaux"
$script:repo    = ".dotfiles"

$script:dotfilesInstallDir = "$env:USERPROFILE\.dotfiles"

#Install Scoop and chocolatey
Write-Output "Installing Scoop..."
if (!(CommandExists("scoop"))) {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-Expression (new-object net.webclient).downloadstring('https://get.scoop.sh')
}
else {
    Write-Warn "Scoop Already installed"
}

if (!(CommandExists("choco")))
{
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
else {
    Write-Warn "Chocolatey Already installed"
}

#Install git so we can clone the repo to the local machine
if (!(CommandExists("git"))) {
    choco install git -y --limit-output -params '"/GitOnlyOnPath /NoShellIntegration"'
    #scoop install git
    #Reload Path
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

Remove-Item $script:dotfilesInstallDir -Force

git clone "https://github.com/$script:account/$script:repo" $script:dotfilesInstallDir


Push-Location $script:dotfilesInstallDir

$local:caption = "Choose Action";
$local:message = "Which bootstrapper do you wish to run?";
$local:co = new-Object System.Management.Automation.Host.ChoiceDescription "&Common Only","Common Only";
$local:h = new-Object System.Management.Automation.Host.ChoiceDescription "&Home","Home";
$local:w = new-Object System.Management.Automation.Host.ChoiceDescription "&Work","Work";
$local:choices = [System.Management.Automation.Host.ChoiceDescription[]]($local:co,$local:h, $local:w);
$local:answer = $host.ui.PromptForChoice($caption,$message,$choices,0)

switch ($local:answer){
    0 {& .\bootstrap.ps1; break}
    1 {& .\bootstrap_home.ps1 ; break}
    3 {& .\bootstrap_work.ps1 ; break}
}

Pop-Location