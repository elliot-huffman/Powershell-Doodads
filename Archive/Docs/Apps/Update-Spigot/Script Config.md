# Configuration of the Script

## There are two methods for configuring the script:

#### 1. Command Line Arguments
Issuing command line interface (CLI) arguments is the recommended method of using and changing your settings. It is most useful because you do not have to edit the script directly and your settings will be retained across script updates.

_**Recommended way of specifying configuration options**_

#### 2. Editing Variables
If you the script's variables directly then you will not have to specify any arguments for the script. Your changes will be lost if you replace your script with the latest version. I would recommend making use of the command line arguments for normal operation.

_Reference given for special configurations, not recommended_

#### List of configuration options:
 - <a href="#verbosity">Verbosity</a>
 - <a href="#name-of-console-window">Name of Console Window</a>
 - <a href="#server-directory">Server Directory</a>
 - <a href="#server-start-script-name">Server Start Script Name</a>
 - <a href="#build-directory">Build Directory</a>
 - <a href="#spigot-version">Spigot Version</a>
 - <a href="#git-bash-installation-location">Git Bash Installation Location</a>


## Explanation for each option:

---

### Verbosity
The verbosity setting is for setting the log options of the script.
The None setting will disable the output of the logging system, essentially disabling the log file.
The Normal (default) setting will only produce log entries if there is an error or when the script finishes successfully.
The Debug setting will make the script spit a log entry for each step in the process.

**CLI Examples:**

`.\AutoUpdate.ps1 -Verbosity "None"`

`.\AutoUpdate.ps1 -Verbosity "Debug"`

**Script Edit Examples:**

`param([string]$Verbosity="None")`

`param([string]$Verbosity="Debug")`

---

### Name of Console Window
The update script stops the server by searching for a window that has a specific name. After it finds the window of that name it types the stop command in the window and press enter.

This option is crucial to be set properly. Because if the server has not been stopped the automatic update cannot continue due to the server executable still being used (the file is locked).

As a server admin you will want to include an option in your server start script that changes the title of your server instance. In a batch file you can accomplish this by the `title` command. In PowerShell you can edit the `$host.ui.RawUI.WindowTitle = "Some string here"` variable to produce the same effect.

**CLI Examples:**

`.\AutoUpdate.ps1 -WindowName "My Minecraft Server"`

`.\AutoUpdate.ps1 -WindowName "Spigot Server Instance 25"`

**Script Edit Examples:**

`param([string]$WindowName="My Minecraft Server")`

`param([string]$WindowName="Spigot Server Instance 25")`

---

### Server Directory
This setting is the full path to the server directory. The server directory is the folder where your spigot-x.jar file is located.

This setting is used for the log location, server executable destination (where the file that BuildTools.jar makes goes) and the start server script location.

**CLI Examples:**

`.\AutoUpdate.ps1 -ServerDir "D:\MC\"`

`.\AutoUpdate.ps1 -ServerDir "C:\Program Files\Spigot\bin\"`

**Script Edit Examples:**

`param([string]$ServerDir="C:\Users\YourName\Desktop\Spigot\")`

`param([string]$ServerDir="D:\Servers\Minecraft\Spigot\Instance14\")`

---

### Server Start Script Name
This option is used to automatically start the server again after the new server executable has been moved in place.

Your start script needs to be present in the same directory that your spigot server is in.

Specify the name of the start script file for the automatic updater to execute.

**CLI Examples:**

`.\AutoUpdate.ps1 -ServerStartScript "start.bat"`

`.\AutoUpdate.ps1 -ServerStartScript "some complex name here.ps1"`

**Script Edit Examples:**

`param([string]$ServerStartScript="start_instance_4.ps1")`

`param([string]$ServerStartScript="Spigot For The Win.bat")`

---

### Build Directory
This options specifies the name of the folder that the build tools will be downloaded to and executed in.

This option REQUIRES that the path to the folder is unix style. E.G. `D:/MC/Build/`

Do NOT use windows style paths for this option as the buildtools will not be able to build the new spigot server. E.G. 'D:\MC\Build\`

I REPEAT, do not use Windows style paths!!!!

**CLI Examples:**

`.\AutoUpdate.ps1 -BuildDir "D:/CI/Minecraft/1.11/build/"`

`.\AutoUpdate.ps1 -BuildDir "C:/Users/Spigot/Documents/SpigotBuild/"`

**Script Edit Examples:**

`param([string]$BuildDir="C:/Build/")`

`param([string]$BuildDir="D:/Program Files (x86)/Spigot/Build/")`

---

### Spigot Version
This option tells the build tools which version you want to build automatically.

The default setting is set to the latest version `"latest"`.

The available options are listed here: https://www.spigotmc.org/wiki/buildtools/#versions

**CLI Examples:**

`.\AutoUpdate.ps1 -BuildVersion "1.11"`

`.\AutoUpdate.ps1 -BuildVersion "1.10"`

**Script Edit Examples:**

`param([string]$BuildVersion="1.9.4")`

`param([string]$BuildVersion="1.8.8")`

---

### Git Bash Installation Location
This option is completely optional and usually does not need to be edited.

If you installed Git Bash to a non default location then you will need to update this option to reflect your custom settings. This also would need to be changed if you use the 32bit version on a 64bit computer.

The default setting is `"C:\Program Files\Git\bin\bash.exe"`

**CLI Examples:**

`.\AutoUpdate.ps1 -GitBashLocation "C:\Program Files (x86)\Git\bin\bash.exe"`

`.\AutoUpdate.ps1 -GitBashLocation "D:\Program Files\Git\bin\bash.exe"`

**Script Edit Examples:**

`param([string]$GitBashLocation="D:\Programs\Git\bin\bash.exe")`

`param([string]$GitBashLocation="C:\Git\bin\bash.exe")`
