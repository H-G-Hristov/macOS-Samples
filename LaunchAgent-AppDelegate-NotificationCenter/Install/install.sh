#!/bin/sh

#  install.sh
#  LaunchAgent
#
#  Created by Hristo Hristov on 1/5/21.
#

# User constants

source "Common/user.sh" # Include user settings

# Constants

agentPList="$agentName.app.plist"
sourceFile="Resources/template.app.plist"
installDir="$HOME/Library/LaunchAgents/"

# Functions

install() {
    if [[ ! -e $installDir ]]; then
        echo "Making launch agents directory: $installDir"
        mkdir -p $installDir
    fi

    if [[ ! -e $installDir ]]; then
        echo "Directory not found: $installDir"
        echo "Failed to install: $agentPList"
    else
        echo "Installing: $agentPList"
        echo "  to: $installDir"
        plistFile="$installDir/$agentPList"
        sed "s|\$AGENT_NAME|$agentName|g" $sourceFile | sed "s|\$HOME|$HOME|g" | sed "s|\$APP_NAME|$baseName|g" | sed "s|\$APP_BUILD_STR|$appBuildStr|g" > $plistFile
    fi
}

uninstall() {
    if [[ ! -e $installDir ]] ; then
        echo "Directory not found: $installDir"
        echo "Failed to install: $agentPList"
    else
        filePath="$installDir/$agentPList"
        
        if [[ ! -e $filePath ]]; then
            echo "Agent is not installed: $agentPList"
            echo "File not found: $filePath"
        else
            echo "Uninstalling agent: $agentPList"
            rm $filePath
        fi
    fi
}

printHelp() {
    echo "Usage: $0 [-u | -h]"
    echo "       $0           - installs the agents .plist"
    echo "       $0 -u        - uninstalls the agents .plist"
    echo "       $0 -h        - prints this usage info"
}

# Main

case $1 in
    -u | --uninstall )
        uninstall
        exit
        ;;
    -h | --help )
        printHelp
        ;;
    * )
        install
esac
