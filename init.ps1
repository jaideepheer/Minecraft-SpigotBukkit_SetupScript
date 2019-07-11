$Strings = @{
    BuildTools = @{
        path="./BuildTools/";
        url="https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
    }
}
function Initialize-BuildTools
{
    Write-Information "Setting up BuildTools environment now..."
    Remove-Item -Path $Strings["BuildTools"]["path"] -Recurse -Force -ErrorAction Ignore
    New-Item -Path $Strings["BuildTools"]["path"] -ItemType Directory > $null
    Push-Location $Strings["BuildTools"]["path"]
        Invoke-WebRequest -Uri $Strings["BuildTools"]["url"] -OutFile "BuildTools.jar"
    Pop-Location
    Write-Information "BuildTools environment setup complete."
}

function Read-RegexFormattedInput
{
    Param(
        [Parameter(Mandatory=$true, HelpMessage="Regex to match with input.")]
        [regex]
        $Regex,
        [Parameter(Mandatory=$true, HelpMessage="Prompt string to display.")]
        [string]
        $Prompt,
        [Parameter(Mandatory=$true, HelpMessage="Default input value.")]
        [string]
        $Default
    )
    while($true)
    {
        $input = Read-Host -Prompt $Prompt
        if($input.Equals("")){ $input = $Default }
        if($Regex.IsMatch($input))
        {
            break
        }
        else 
        {
            Write-Error "Invalid input."
        }
    }
    return $input
}

if( -not (Test-Path $Strings["BuildTools"]["path"]) )
{
    Write-Warning "BuildTools not found."
    Initialize-BuildTools
}

# input minecraft ver.
$rev = Read-RegexFormattedInput -Prompt "Enter the minecraft version for this server (default:latest)" -Default "latest" -Regex "(1\.\d{1,2}(\.\d)?)|latest"
# input and create server dir.
while($true)
{
    $server_dir = Read-RegexFormattedInput -Prompt "Enter the server directory name (default:$rev)" -Default $rev -Regex "[-_\w\d\.]+"
    $server_dir = Resolve-Path -Path $server_dir
    if(Test-Path $server_dir)
    {
        Write-Warning "Server directory already exists."
        break
    }
    New-Item -Path $server_dir -ItemType Directory -ErrorVariable oops > $null
    if($oops)
    {
        Write-Error "Couldn't create server folder. Maybe the folder name was invalid."
        continue
    }
    break
}
# load minecraft server in directory
Push-Location $Strings["BuildTools"]["path"]
    #java -jar BuildTools.jar --rev $rev --output-dir $server_dir
Pop-Location
Write-Host "Server compilation done."
# make run.bat files
Push-Location $server_dir
    Get-ChildItem $server_dir -Filter *.jar | Foreach-Object {
        Set-Content (-join("RUN ",$_.BaseName,".bat")) "( java -Xms1024M -Xmx2048M -jar $_ ) & pause" -Encoding Ascii
    }
Pop-Location
