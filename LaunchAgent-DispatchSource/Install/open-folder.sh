#!/bin/sh

#  open-folder.sh
#  LaunchAgent
#
#  Created by Hristo Hristov on 1/8/21.
#

# User constants

source "Common/user.sh" # Include user settings

# Constants

buildAppPackageName="$baseName-$appBuildStr"
buildAppPackageDirectory="$HOME/Library/Developer/Xcode/DerivedData/$buildAppPackageName/Build/Products/Debug/$baseName.app/Contents/MacOS/"
launchAgentsDirectory="$HOME/Library/LaunchAgents"
downloadsDirectory="$HOME/Downloads"
downloadsAppContainerDirectory="$HOME/Library/Containers/$agentName/Downloads"
logDirectory="$downloadsDirectory/$baseName"
xcodeDirectory="$HOME/Library/Developer/Xcode/DerivedData/"

function newTerminal() {
    if [[ $# -eq 0 ]]; then
        open -a "Terminal" "$PWD"
    else
        open -a "Terminal" "$@"
    fi
}


printHelp() {
    echo "Usage: $0 [-la | -pd | -h] [-t]"
    echo "       $0           - prints this usage info"
    echo "       $0 -da       - opens Downloads app container directory in Finder"
    echo "       $0 -dd       - opens Downloads directory in Finder"
    echo "       $0 -la       - opens LaunchAgents directory in Finder"
    echo "       $0 -ld       - opens log directory in Finder"
    echo "       $0 -pd       - opens build directory in Finder"
    echo "       $0 -xc       - opens Xcode build directory"
    echo "       $0 -h        - prints this usage info"
}

case $1 in
    -da | --downloads-app-container )
        targetLocation=$downloadsAppContainerDirectory
        ;;
    -dd | --downloads )
        targetLocation=$downloadsDirectory
        ;;
    -la | --launch-agents )
        targetLocation=$launchAgentsDirectory
        ;;
    -ld | --log-directory )
        targetLocation=$logDirectory
        ;;
    -pd | --package-directory )
        targetLocation=$buildAppPackageDirectory
        ;;
    -xc | --xcode-directory )
        targetLocation=$xcodeDirectory
        ;;
    -h | --help )
        printHelp
        exit
        ;;
    * )
        printHelp
        exit
esac

if [[ $2 = -t ]] ; then
    terminalCommand="-a Terminal.app"
fi

open $terminalCommand $targetLocation
