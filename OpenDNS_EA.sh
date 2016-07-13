#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                             #
#  Extension Attribute to report whether or not the OpenDNS helper tool is installed and      #
#  enabled on a Mac, and to automatically install or re-enable the tool after the allowed     #
#  disablement period has lapsed. The date on which the tool was disabled and re-enabled is   #
#  written to a log.                                                                          #
#                                                                                             #
#                -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -                #
#                                                                                             #
#                 This script was created by Martyn Powell on 13th July 2016                  #
#                                                                                             #
#                -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -  *  -                #
#                                                                                             #
#  This program is free software: you can redistribute it and/or modify it under the terms    #
#  of the GNU General Public License as published by the Free Software Foundation, either     #
#  version 3 of the License, or (at your option) any later version.                           #
#                                                                                             #
#  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;  #
#  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  #
#  See the GNU General Public License for more details.                                       #
#                                                                                             #
#  You should have received a copy of the GNU General Public License along with this program. #
#  If not, see <http://www.gnu.org/licenses/>.                                                #
#                                                                                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# - - - - - - - - - - - - - - - - SET REQUIRED VARIABLES HERE - - - - - - - - - - - - - - - - #

# How many hours can OpenDNS be disabled before being re-enabled?
disablementAllowance="36"

# Where is the OpenDNS app installed on devices in your environment?
opendnsLocation="/Applications/OpenDNS Roaming Client/RoamingClientMenubar.app"

# Where is the lock file located?
opendnsLock="/Library/Application Support/OpenDNS Roaming Client/force_off.flag"

# Create an ongoing policy to install OpenDNS and enter your chosen custom trigger here:
installTrigger="InstallOpenDNS"

# Directory of log file to record details of OpenDNS bypass periods:
opendnsLogFile="/Library/Logs/OpenDNS.log"

# - - - - - - - - - - - - - - - - DO NOT EDIT BELOW THIS LINE - - - - - - - - - - - - - - - - #

# Converting allowance to a UNIX duration...
disablementAllowance_UNIX=$(($disablementAllowance * 12000))

# Establishing the current date in UNIX time...
currentTime_UNIX=`date +%s`

echo "Checking if OpenDNS helper is installed..."
if [ -x "$opendnsLocation" ]; then
	echo "OpenDNS helper installed."
	echo "Checking status of OpenDNS..."
	if [ -f "$opendnsLock" ]; then
		echo "OpenDNS is disabled."
		echo "Checking time OpenDNS was disabled..."
		dateDisabled_UNIX=`stat -f "%m" "$opendnsLock"`
		echo "Calculating duration OpenDNS has been disabled..."
		durationDisabled_UNIX=`expr $currentTime_UNIX - $dateDisabled_UNIX`
		echo "Evaluating duration against re-enablement policy..."
			if [[ $durationDisabled_UNIX -ge $disablementAllowance_UNIX ]]; then
				echo "Allowance elapsed. Re-enabling OpenDNS now."
				rm "$opendnsLock"
				touch "$opendnsLogFile"; date=`date`; echo "$date : ----> RE-ENABLED" >> "$opendnsLogFile"
				echo "<result>Re-Enabled</result>"
			else
				echo "Allowance remaining. OpenDNS will remain disabled."
				touch "$opendnsLogFile"; date=`date`; echo "$date : ------> DISABLED" >> "$opendnsLogFile"
				echo "<result>Disabled</result>"
			fi
	else
		echo "OpenDNS is enabled."
		touch "$opendnsLogFile"; date=`date`; echo "$date : --> ENABLED" >> "$opendnsLogFile"
		echo "<result>Enabled</result>"
	fi
else
	echo "OpenDNS helper is not installed."
	echo "Initiating installation of OpenDNS helper..."
	jamf policy -event $installTrigger
	echo "OpenDNS helper has been installed."
	touch "$opendnsLogFile"; date=`date`; echo "$date : --------> INSTALLED" >> "$opendnsLogFile"
	echo "<result>Installed</result>"
fi
