#!/bin/sh

#  agent-cmd.sh
#  LaunchAgent
#
#  Created by Hristo Hristov on 1/5/21.
#

# User constants

source "Common/user.sh" # Include user settings

# Constants

agentPList="$agentName.app.plist"
agentsDir="$HOME/Library/LaunchAgents/"
launchAgent="$agentsDir$agentPList"

# Variables

shouldPrintLaunchdInfo=true

# Functions

agentLoad() {
    echo "Launching Agent: $launchAgent"
    launchctl load $launchAgent
}

agentUnload() {
    echo "Unloading Agent: $launchAgent"
    launchctl unload $launchAgent
}

agentStart() {
    echo "Starting Agent: $launchAgent"
    launchctl start $launchAgent
}

agentStop() {
    echo "Stopping Agent: $launchAgent"
    launchctl stop $launchAgent
}

printHelp() {
    echo "Usage: $0 [-l | -u | -s | -t | -h]"
    echo "       $0                           - prints this usage info"
    echo "       $0 -l                        - loads the agent"
    echo "       $0 -u                        - unloads the agent"
    echo "       $0 -s                        - starts the agent"
    echo "       $0 -t                        - terminates the agent"
    echo "       $0 -h                        - prints this usage info"
    
    shouldPrintLaunchdInfo=false
}

# Main

case $1 in
    -l | --load )
        agentLoad
        ;;
        
    -u | --unload )
        agentUnload
        ;;
        
    -s | --start )
        agentStart
        ;;
        
    -t | --stop )
        agentStop
        ;;
        
    -h | --help )
        printHelp
        ;;
        
    * )
        printHelp
esac

if [ "$shouldPrintLaunchdInfo" = true ] ; then
    launchctl list | grep $agentName
fi
