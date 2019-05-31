#LAMW Manager for windows
$LAMW_MANAGER_VERSION="0.3.0"
$HOME_USER=$env:homepath
$ROOT_LAMW="$home_user" + "\" + "LAMW"
$ANT_URL="http://ftp.unicamp.br/pub/apache/ant/binaries/apache-ant-1.10.5-bin.zip"
$ANT_ZIP="apache-ant-1.10.5-bin.zip"
$ANT_HOME="apache-ant-1.10.5"
$ANT_VERSION="1.10.5"

$GRADLE_URL="http://services.gradle.org/distributions/gradle-4.4.1-bin.zip"
$GRADLE_ZIP="gradle-4.4.1-bin.zip"
$GRADLE_HOME="gradle-4.4.1"
$GRADLE_VERSION="4.4.1"


$SDK_TOOLS_URL="https://dl.google.com/android/repository/sdk-tools-windows-4333796.zip"
$SDK_TOOLS_ZIP="sdk-tools-windows-4333796.zip"
$SDK_TOOLS_VERSION="26.1.1"

$NDK_URL=""
$NDK_ZIP=""
$NDK_VERSION=""

$SDK_VERSION="28"
$ARCH=""
$OS_PREBUILD=""
$NATIVE_WINDOWS_SUPPPORT=0
$OLD_FPC_PATH="C:\laz4android1.8\fpc\3.0.4\bin\i386-win32"
$MSYS_EXEC=""
$LAZ4ANDROID_STABLE_VERSION="2.0.0"
$LAZ4ANDROID_HOME="C:\LAMW4Windows\laz4android" + $LAZ4ANDROID_STABLE_VERSION 
$FPC_PATH= $LAZ4ANDROID_HOME +"\fpc\3.0.4\bin\i386-win32"

#Baixa um arquivo da Web , 
#ARG0 eh a url
#ARG1 eh o caminho do diretorio  com o nome do arquivo exemplo C:\Users\Daniel\apache-ant.zip
function getFile(){

    #add support wget -OutFile
    $URL=$ARGS[0];
    $client = New-Object System.Net.WebClient;
    $path=$ARGS[1];
    echo "url=$URL path=$path";
    $client.DownloadFile($URL, $path);
    if ( $? -eq $false ){
        $client.DownloadFile($URL, $path);
        if ( $? -eq $false ){
            echo "Falls, try latter!"
        }
    }
}
function writeLAMWManagerbat(){
    $MSYS_EXEC=prepareEnv
    $BASH_PATH=$MSYS_EXEC + '\' + 'bash.exe'
    $buffer_lamw=@(
    '@echo off',
    "SET BASH_PATH=$BASH_PATH",
    "cd C:\lamw_manager",
    "",
    "if exist %BASH_PATH% (goto :RunLAMWMgr ) else (goto :RestoreMsys)",
    "",
    "",
    ":RestoreMsys",
    "C:\lamw_manager\repair-msys.bat",
    "C:\lamw_manager\preinstall.bat",
    "goto :End",
    "",
    "",
    ":RunLAMWMgr",
    "echo %BASH_PATH%",
    "%BASH_PATH% simple-lamw-install.sh %*",
    "goto :End",
    "",
    "",
    ":End",
    "pause"
    )
    $lamw_manager_bat_path='C:\lamw_manager\lamw_manager.bat'
    if ( ! (Test-Path $lamw_manager_bat_path)) {
        $fp=[System.IO.StreamWriter] $lamw_manager_bat_path
        for($i=0;$i -lt $buffer_lamw.Count;$i++){
            $str=$buffer_lamw[$i]
            $fp.WriteLine($str)
        }
        $fp.close()
    }
}


#this function enable package manager 
function enableChocolateyPackageManager(){
    $psh_path="$env:SystemRoot\System32"
    echo $psh_path# powershell.exe Set-ExecutionPolicy AllSigned
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    $env:PATH="$env:PATH;$env:ALLUSERSPROFILE\chocolatey\bin"

}
#[bool]
function installDependencies(){
    $packages = @("mingw","msys2", "git.install","7zip.install", "wget" )
    for($i=0;$i -lt $packages.Count;$i++){
        choco install  $packages[$i] -y 
        if ( $? -eq $false ){
            choco install $packages[$i] -y --force
            if ( $? -eq $false ){
                echo "Install falls, try later!"
                exit 1
            }
        }
    }
}
function detectArch(){
   [bool] $flag_arch=systeminfo | Select-String -pattern 'x64-based'
    if ( $flag_arch -eq $true ){
        return "amd64"
    }else {
        return "x86"
    }
}
function prepareEnv(){
    $ARCH=detectArch
    if ( $ARCH = "amd64" ){
        $MSYS_EXEC="C:\tools\msys64\usr\bin"
    }else{
        $MSYS_EXEC="C:\tools\msys32\usr\bin"
    }
    return $MSYS_EXEC
}

#funcao para obter o ultimo caractere 
function getLastChar(){
    $test_str=$ARGS[0]
    $lengh_str=$test_str.Length - 1
    $ret=$test_str.Substring($lengh_str,1)
    echo $ret
    return $ret
}
#funcao para atualizar as variaveis de ambiente do sistema
function RepairPath(){
    $lamw_cfg_path="C:\laz4lamwpaths.txt"
    $old_env_path=$env:path
    $new_path=""
    #echo "old_env_path=$old_env_path"
    if (  (Test-Path $lamw_cfg_path ) ){
        if ( $old_env_path.Contains($MSYS_EXEC)){
            $old_env_path=$old_env_path.Replace("$MSYS_EXEC"+';',"")
        }

        if ( $old_env_path.Contains($OLD_FPC_PATH )){
            $old_env_path=$old_env_path.Replace("$OLD_FPC_PATH"+';','')
        }
        
        #verifica se o último caractere é um ; (ponto e vírgula)
        if ( ! ( ( getLastChar $old_env_path ) -eq ';') ){
            $old_env_path= $old_env_path + ';'
        }else{
            echo "always exists ';'"
        }
        $new_path=$old_env_path + $MSYS_EXEC +';'  + $FPC_PATH  + ';'
        echo "nova_path $new_path"
        SETX /M PATH "$new_path"
        rm -Force $lamw_cfg_path
        $env:path = $env:path + $new_path

    }else{
       if ( ! ( ( getLastChar $old_env_path ) -eq ';') ){
            $old_env_path= $old_env_path + ';'
        }else{
            echo "always exists ';'"
        }
        if ( ! $old_env_path.Contains($MSYS_EXEC)){
            $new_path=$new_path + $MSYS_EXEC +';'
        
            if (! $old_env_path.Contains($FPC_PATH+ ';')){
                $new_path=$new_path + $FPC_PATH + ';'
            }
            $new_path= $old_env_path + $new_path
            if ( $new_path.Length -ge 1024 ){
                echo "Warm: Your new variable% PATH% variable has more than 1024 characters and therefore will not be installed! You should remove unneeded paths"
            }else{
                echo "new_path=$new_path"
                SETX /M PATH "$new_path"
            }
            $env:path = $env:path + $new_path
        }else{
            echo "always path updated..."
        }
    }
}

function installAndroidAPIs(){
    $env:PATH='C:\Program Files\Zulu\zulu-8\bin;' + $env:PATH

    $SDK_MANAGER_CMD_PARAMETERS2=@( "android-26" ,"platform-tools" ,"build-tools-26.0.2"  ,"extra-google-google_play_services" ,"extra-android-m2repository" ,"extra-google-m2repository" ,"extra-google-market_licensing", "extra-google-market_apk_expansion")
    $SDK_MANAGER_FAILS=@("platform","platform-tools", "build-tools", "extras/google/google-google_play_services", "extras/android/m2repository", "extras/google/market_licensing" , "extras/google/market_apk_expansion")   
    $env:PATH="C:\Users\Daniel\LAMW\sdk\tools;" + $env:path
    $aux=""
    echo $env:path
    for($i=0; $i -lt $SDK_MANAGER_CMD_PARAMETERS2.Count; $i++){
        echo y | android.bat "update" "sdk" "--all" "--no-ui" "--filter" $SDK_MANAGER_CMD_PARAMETERS2[$i]  --force
        if ( $? -eq $false ){
            $aux="$ROOT_LAMW\sdk\tools" + '\' + $SDK_MANAGER_FAILS[$i]
            rmdir -Recurse -Force $aux
            echo y | android.bat "update" "sdk" "--all" "--no-ui" "--filter" $SDK_MANAGER_CMD_PARAMETERS2[$i]  --force
        }
    }
}

$ARCH=detectArch
$MSYS_EXEC=prepareEnv
writeLAMWManagerbat
RepairPath
enableChocolateyPackageManager
installDependencies
$bash_path=$MSYS_EXEC + '\' + 'bash.exe' 
if ( Test-Path $bash_path ){
  & $bash_path simple-lamw-install.sh  
}else{
    echo "Bash install falls, trying repair ..."
    choco uninstall mingw -y 
    choco uninstall msys2 -y
   $msys_falls_path=$env:homedrive + '\' +'tools'
    if ( Test-Path $msys_falls_path ){
        Remove-Item $msys_falls_path -Force -Recurse 
        if ( $? -eq $false ){
          Remove-Item $msys_falls_path -Force -Recurse   
        }
    }
    installDependencies
    & $bash_path simple-lamw-install.sh
}

#getFile $ANT_URL C:\Users\Daniel