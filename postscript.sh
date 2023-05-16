#!/bin/bash
set -e

TOTAL_EXECUTION_START_TIME=$SECONDS
SOURCE_DIR="$1"
DESTINATION_DIR="$2"
INTERMEDIATE_DIR="$3"

if [ -f /opt/oryx/logger ]; then
        source /opt/oryx/logger
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory '$SOURCE_DIR' does not exist." 1>&2
    exit 1
fi


cd "$SOURCE_DIR"
SOURCE_DIR=$(pwd -P)

if [ -z "$DESTINATION_DIR" ]
then
    DESTINATION_DIR="$SOURCE_DIR"
fi

if [ -d "$DESTINATION_DIR" ]
then
    cd "$DESTINATION_DIR"
    DESTINATION_DIR=$(pwd -P)
fi



if [ ! -z "$INTERMEDIATE_DIR" ]
then
        echo "Using intermediate directory '$INTERMEDIATE_DIR'."
        if [ ! -d "$INTERMEDIATE_DIR" ]
        then
                echo
                echo "Intermediate directory doesn't exist, creating it...'"
                mkdir -p "$INTERMEDIATE_DIR"
        fi

        cd "$INTERMEDIATE_DIR"
        INTERMEDIATE_DIR=$(pwd -P)
        cd "$SOURCE_DIR"
        echo
        echo "Copying files to the intermediate directory..."
        START_TIME=$SECONDS
        excludedDirectories=""

                excludedDirectories+=" --exclude __oryx_packages__"

                excludedDirectories+=" --exclude antenv"

                excludedDirectories+=" --exclude antenv.zip"

                excludedDirectories+=" --exclude antenv.tar.gz"

                excludedDirectories+=" --exclude .git"



        rsync -rcE --delete $excludedDirectories . "$INTERMEDIATE_DIR"

        ELAPSED_TIME=$(($SECONDS - $START_TIME))
        echo "Done in $ELAPSED_TIME sec(s)."
        SOURCE_DIR="$INTERMEDIATE_DIR"
fi

echo
echo "Source directory     : $SOURCE_DIR"
echo "Destination directory: $DESTINATION_DIR"
echo



if grep -q cli "/opt/oryx/.imagetype"; then
echo 'Installing common platform dependencies...'
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
  git
rm -rf /var/lib/apt/lists/*
echo 'Installing python specific dependencies...'
echo 'Installing python tooling and language...'
PYTHONIOENCODING="UTF-8"
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
  make unzip libpq-dev moreutils python3-pip swig unixodbc-dev build-essential gdb lcov pkg-config libbz2-dev libffi-dev libgdbm-dev liblzma-dev libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev lzma lzma-dev tk-dev uuid-dev zlib1g-dev
rm -rf /var/lib/apt/lists/*
tmpDir="/opt/tmp"
imagesDir="$tmpDir/images"
buildDir="$tmpDir/build"
mkdir -p /usr/local/share/pip-cache/lib
chmod -R 777 /usr/local/share/pip-cache
pip3 install pip --upgrade
python3 -m pip install --upgrade cython
pip3 install --upgrade cython
. $buildDir/__pythonVersions.sh
$imagesDir/installPlatform.sh python $PYTHON38_VERSION
[ -d "/opt/python/$PYTHON38_VERSION" ] && echo /opt/python/$PYTHON38_VERSION/lib >> /etc/ld.so.conf.d/python.conf
ldconfig
cd /opt/python
ln -s $PYTHON38_VERSION 3.8
ln -s $PYTHON38_VERSION latest
ln -s $PYTHON38_VERSION stable
fi
PLATFORM_SETUP_START=$SECONDS
echo
echo "Downloading and extracting 'python' version '3.10.8' to '/tmp/oryx/platforms/python/3.10.8'..."
rm -rf /tmp/oryx/platforms/python/3.10.8
mkdir -p /tmp/oryx/platforms/python/3.10.8
cd /tmp/oryx/platforms/python/3.10.8
PLATFORM_BINARY_DOWNLOAD_START=$SECONDS
platformName="python"
export DEBIAN_FLAVOR=bullseye
echo "Detected image debian flavor: $DEBIAN_FLAVOR."
if [ "$DEBIAN_FLAVOR" == "stretch" ]; then
curl -D headers.txt -SL "https://oryx-cdn.microsoft.io/python/python-3.10.8.tar.gz" --output 3.10.8.tar.gz >/dev/null 2>&1
else
curl -D headers.txt -SL "https://oryx-cdn.microsoft.io/python/python-$DEBIAN_FLAVOR-3.10.8.tar.gz$ORYX_SDK_STORAGE_ACCOUNT_ACCESS_TOKEN" --output 3.10.8.tar.gz >/dev/null 2>&1
fi
PLATFORM_BINARY_DOWNLOAD_ELAPSED_TIME=$(($SECONDS - $PLATFORM_BINARY_DOWNLOAD_START))
echo "Downloaded in $PLATFORM_BINARY_DOWNLOAD_ELAPSED_TIME sec(s)."
echo Verifying checksum...
headerName="x-ms-meta-checksum"
checksumHeader=$(cat headers.txt | grep -i $headerName: | tr -d '\r')
checksumHeader=$(echo $checksumHeader | tr '[A-Z]' '[a-z]')
checksumValue=${checksumHeader#"$headerName: "}
rm -f headers.txt
echo Extracting contents...
tar -xzf 3.10.8.tar.gz -C .
if [ "$platformName" = "golang" ]; then
echo "performing sha256sum for : python..."
echo "$checksumValue 3.10.8.tar.gz" | sha256sum -c - >/dev/null 2>&1
else
echo "performing sha512 checksum for: python..."
echo "$checksumValue 3.10.8.tar.gz" | sha512sum -c - >/dev/null 2>&1
fi
rm -f 3.10.8.tar.gz
PLATFORM_SETUP_ELAPSED_TIME=$(($SECONDS - $PLATFORM_SETUP_START))
echo "Done in $PLATFORM_SETUP_ELAPSED_TIME sec(s)."
echo
oryxImageDetectorFile="/opt/oryx/.imagetype"
oryxOsDetectorFile="/opt/oryx/.ostype"
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "dotnet" ] && grep -q "jamstack" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is dotnet.."
PATH=/opt/dotnet/3.10.8/dotnet:$PATH
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "dotnet" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is dotnet.."
source /opt/tmp/build/createSymlinksForDotnet.sh
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "nodejs" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is nodejs.."
mkdir -p /home/codespace/nvm
ln -sfn /opt/nodejs/3.10.8 /home/codespace/nvm/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "php" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is php.."
mkdir -p /home/codespace/.php
ln -sfn /opt/php/3.10.8 /home/codespace/.php/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "python" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
   echo "image detector file exists, platform is python.."
  [ -d "/opt/python/$VERSION" ] && echo /opt/python/3.10.8/lib >> /etc/ld.so.conf.d/python.conf
  ldconfig
  mkdir -p /home/codespace/.python
  ln -sfn /opt/python/3.10.8 /home/codespace/.python/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "java" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is java.."
mkdir -p /home/codespace/java
ln -sfn /opt/java/3.10.8 /home/codespace/java/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ "$platformName" = "ruby" ] && grep -q "vso-" "$oryxImageDetectorFile"; then
echo "image detector file exists, platform is ruby.."
mkdir -p /home/codespace/.ruby
ln -sfn /opt/ruby/3.10.8 /home/codespace/.ruby/current
fi
if [ -f "$oryxImageDetectorFile" ] && [ -f "$oryxOsDetectorFile" ] && [ "$platformName" = "python" ] && grep -q "githubactions" "$oryxImageDetectorFile" && grep -q "BULLSEYE" "$oryxOsDetectorFile"; then
  echo "image detector file exists, platform is python.."
  echo "OS detector file exists, OS is bullseye.."
  if [ '3.10.8' == 3.7* ] || [ '3.10.8' == 3.8* ]; then
    curl -LO http://ftp.de.debian.org/debian/pool/main/libf/libffi/libffi6_3.2.1-9_amd64.deb
    dpkg -i libffi6_3.2.1-9_amd64.deb
    rm libffi6_3.2.1-9_amd64.deb
  fi
fi
echo > /tmp/oryx/platforms/python/3.10.8/.oryx-sdkdownload-sentinel





cd "$SOURCE_DIR"


if [ -f /opt/oryx/benv ]; then
        source /opt/oryx/benv python=3.10.8 dynamic_install_root_dir="/tmp/oryx/platforms"
fi





export SOURCE_DIR
export DESTINATION_DIR


mkdir -p "$DESTINATION_DIR"





cd "$SOURCE_DIR"
set -e
# TODO: refactor redundant code. Work-item: 1476457

declare -r TS_FMT='[%T%z] '
declare -r REQS_NOT_FOUND_MSG='Could not find setup.py or requirements.txt; Not running pip install. More information: https://aka.ms/requirements-not-found'
echo "Python Version: $python"
PIP_CACHE_DIR=/usr/local/share/pip-cache


COMMAND_MANIFEST_FILE="/tmp/zipdeploy/extracted/oryx-build-commands.txt"


echo "Creating directory for command manifest file if it does not exist"
mkdir -p "$(dirname "$COMMAND_MANIFEST_FILE")"
echo "Removing existing manifest file"
rm -f "$COMMAND_MANIFEST_FILE"

echo "PlatformWithVersion=Python 3.10.8" > "$COMMAND_MANIFEST_FILE"

InstallCommand=""

if [ ! -d "$PIP_CACHE_DIR" ];then
    mkdir -p $PIP_CACHE_DIR
fi


    REQUIREMENTS_TXT_FILE="requirements.txt"



    

    VIRTUALENVIRONMENTNAME=antenv
    VIRTUALENVIRONMENTMODULE=venv
    VIRTUALENVIRONMENTOPTIONS="--copies"
    zippedVirtualEnvFileName=

    echo "Python Virtual Environment: $VIRTUALENVIRONMENTNAME"

    if [ -e "$REQUIREMENTS_TXT_FILE" ]; then
        VIRTUALENVIRONMENTOPTIONS="$VIRTUALENVIRONMENTOPTIONS --system-site-packages"
    fi

    echo Creating virtual environment...

    CreateVenvCommand="$python -m $VIRTUALENVIRONMENTMODULE $VIRTUALENVIRONMENTNAME $VIRTUALENVIRONMENTOPTIONS"
    echo "BuildCommands=$CreateVenvCommand" >> "$COMMAND_MANIFEST_FILE"

    $python -m $VIRTUALENVIRONMENTMODULE $VIRTUALENVIRONMENTNAME $VIRTUALENVIRONMENTOPTIONS

    echo Activating virtual environment...
    printf %s " , $ActivateVenvCommand" >> "$COMMAND_MANIFEST_FILE"
    ActivateVenvCommand="source $VIRTUALENVIRONMENTNAME/bin/activate"
    source $VIRTUALENVIRONMENTNAME/bin/activate

    moreInformation="More information: https://aka.ms/troubleshoot-python"
    if [ -e "$REQUIREMENTS_TXT_FILE" ]
    then
        set +e
        echo "Running pip install..."
        InstallCommand="python -m pip install --cache-dir $PIP_CACHE_DIR --prefer-binary -r $REQUIREMENTS_TXT_FILE | ts $TS_FMT"
        printf %s " , $InstallCommand" >> "$COMMAND_MANIFEST_FILE"
        output=$( ( python -m pip install --cache-dir $PIP_CACHE_DIR --prefer-binary -r $REQUIREMENTS_TXT_FILE | ts $TS_FMT; exit ${PIPESTATUS[0]} ) 2>&1; exit ${PIPESTATUS[0]} )
        pipInstallExitCode=${PIPESTATUS[0]}
        python -m pip install supervisor==4.2.0

        set -e
        echo "${output}"
        if [[ $pipInstallExitCode != 0 ]]
        then
            LogError "${output} | Exit code: ${pipInstallExitCode} | Please review your requirements.txt | ${moreInformation}"
            exit $pipInstallExitCode
        fi
    elif [ -e "setup.py" ]
    then
        set +e
        echo "Running python setup.py install..."
        InstallCommand="$python setup.py install --user| ts $TS_FMT"
        printf %s " , $InstallCommand" >> "$COMMAND_MANIFEST_FILE"
        output=$( ( $python setup.py install --user| ts $TS_FMT; exit ${PIPESTATUS[0]} ) 2>&1; exit ${PIPESTATUS[0]} )
        pythonBuildExitCode=${PIPESTATUS[0]}
        set -e
        echo "${output}"
        if [[ $pythonBuildExitCode != 0 ]]
        then
            LogError "${output} | Exit code: ${pipInstallExitCode} | Please review your setup.py | ${moreInformation}"
            exit $pythonBuildExitCode
        fi
    elif [ -e "pyproject.toml" ]
    then
        set +e
        echo "Running pip install poetry..."
        InstallPipCommand="pip install poetry"
        printf %s " , $InstallPipCommand" >> "$COMMAND_MANIFEST_FILE"
        pip install poetry
        echo "Running poetry install..."
        InstallPoetryCommand="poetry install --no-dev"
        printf %s " , $InstallPoetryCommand" >> "$COMMAND_MANIFEST_FILE"
        output=$( ( poetry install --no-dev; exit ${PIPESTATUS[0]} ) 2>&1)
        pythonBuildExitCode=${PIPESTATUS[0]}
        set -e
        echo "${output}"
        if [[ $pythonBuildExitCode != 0 ]]
        then
            LogWarning "${output} | Exit code: {pythonBuildExitCode} | Please review message | ${moreInformation}"
            exit $pythonBuildExitCode
        fi
    else
        echo $REQS_NOT_FOUND_MSG
    fi

    # For virtual environment, we use the actual 'python' alias that as setup by the venv,
    python_bin=python






    set +e
    if [ -e "$SOURCE_DIR/manage.py" ]
    then
        if grep -iq "Django" "$SOURCE_DIR/$REQUIREMENTS_TXT_FILE"
        then
            echo
            echo Content in source directory is a Django app
            echo Running 'collectstatic'...
            START_TIME=$SECONDS
            CollectStaticCommand="$python_bin manage.py collectstatic --noinput"
            printf %s " , $CollectStaticCommand" >> "$COMMAND_MANIFEST_FILE"
            output=$(($python_bin manage.py collectstatic --noinput; exit ${PIPESTATUS[0]}) 2>&1)
            EXIT_CODE=${PIPESTATUS[0]}
            echo "${output}"
            if [[ $EXIT_CODE != 0 ]]
            then
                recommendation="Please review message"
                LogWarning "${output} | Exit code: ${EXIT_CODE} | ${recommendation} | ${moreInformation}"
            fi
            ELAPSED_TIME=$(($SECONDS - $START_TIME))
            echo "Done in $ELAPSED_TIME sec(s)."
        else
            output="Missing Django module in $SOURCE_DIR/$REQUIREMENTS_TXT_FILE"
            recommendation="Add Django to your requirements.txt file."
            LogWarning "${output} | Exit code: 0 | ${recommendation} | ${moreInformation}"
        fi
    fi
    set -e



ReadImageType=$(cat /opt/oryx/.imagetype)

if [ "$ReadImageType" = "vso-focal" ] || [ "$ReadImageType" = "vso-debian-bullseye" ]
then
    echo $ReadImageType
    cat "$COMMAND_MANIFEST_FILE"
else
    echo "Not a vso image, so not writing build commands"
    rm "$COMMAND_MANIFEST_FILE"
fi


    






if [ "$SOURCE_DIR" != "$DESTINATION_DIR" ]
then
        echo "Preparing output..."



                preCompressedDestinationDir="/tmp/_preCompressedDestinationDir"
                rm -rf $preCompressedDestinationDir
                OLD_DESTINATION_DIR="$DESTINATION_DIR"
                DESTINATION_DIR="$preCompressedDestinationDir"



                        cd "$SOURCE_DIR"

                        echo
                        echo "Copying files to destination directory '$DESTINATION_DIR'..."
                        START_TIME=$SECONDS
                        excludedDirectories=""

                                excludedDirectories+=" --exclude .git"





                        rsync -rcE --links $excludedDirectories . "$DESTINATION_DIR"



                        ELAPSED_TIME=$(($SECONDS - $START_TIME))
                        echo "Done in $ELAPSED_TIME sec(s)."



                DESTINATION_DIR="$OLD_DESTINATION_DIR"
                echo "Compressing content of directory '$preCompressedDestinationDir'..."
                cd "$preCompressedDestinationDir"
                tar -zcf "$DESTINATION_DIR/output.tar.gz" .
                echo "Copied the compressed output to '$DESTINATION_DIR'"

fi


MANIFEST_FILE=oryx-manifest.toml

MANIFEST_DIR=
if [ -z "$MANIFEST_DIR" ];then
        MANIFEST_DIR="$DESTINATION_DIR"
fi
mkdir -p "$MANIFEST_DIR"

echo
echo "Removing existing manifest file"
rm -f "$MANIFEST_DIR/$MANIFEST_FILE"

echo "Creating a manifest file..."

echo "PythonVersion=\"3.10.8\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "pythonBuildCommandsFile=\"/tmp/zipdeploy/extracted/oryx-build-commands.txt\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "virtualEnvName=\"antenv\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "OperationId=\"0e6c33fab7f06ded\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "SourceDirectoryInBuildContainer=\"/tmp/8db55bf3173cc79\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "PlatformName=\"python\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "CompressDestinationDir=\"true\"" >> "$MANIFEST_DIR/$MANIFEST_FILE"

echo "Manifest file created."



OS_TYPE_SOURCE_DIR="/opt/oryx/.ostype"
if [ -f "$OS_TYPE_SOURCE_DIR" ]
then
        echo "Copying .ostype to manifest output directory."
        cp "$OS_TYPE_SOURCE_DIR" "$MANIFEST_DIR/.ostype"
else
        echo "File $OS_TYPE_SOURCE_DIR does not exist. Cannot copy to manifest directory." 1>&2
        exit 1
fi

TOTAL_EXECUTION_ELAPSED_TIME=$(($SECONDS - $TOTAL_EXECUTION_START_TIME))
echo
echo "Done in $TOTAL_EXECUTION_ELAPSED_TIME sec(s)."
