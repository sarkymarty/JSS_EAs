#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                             #
#  Extension Attribute to report whether or not the JSS assigned user is able to unlock the   #
#  FileVault encrypted boot volume. This Extension Attribute is designed to run from the JSS  #
#  and makes use of the JSS API. It will need a hard-coded JSS user account, which should be  #
#  no more than a read-only, API-only user.                                                   #
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
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# - - - - - - - - - - - - - - - - SET REQUIRED VARIABLES HERE - - - - - - - - - - - - - - - - #

# The JSS URL, minus "https://" but including any specified port numbers:
JSS_URL="jss.mycompany.com:8443"

# The username for an API user account in the JSS, only requiring read access:
API_Username="USERNAME"

# The password for the above specified API user account:
API_Password="PASSWORD"

# - - - - - - - - - - - - - - - - DO NOT EDIT BELOW THIS LINE - - - - - - - - - - - - - - - - #

echo "Checking required variables are set."

if [[ $JSS_URL == "" ]]
then
	echo "ERROR : JSS URL required. Please set this in the script variables."
else
	if [[ $API_Username == "" ]]
	then
		echo "ERROR : API username required. Please set this in the script variables."
	else
		if [[ $API_Password == "" ]]
		then
			echo "ERROR : API password required. Please set this in the script variables."
		else

			echo "Getting device serial number..."
			computerSerialNumber=`ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}'`

			echo "Checking for the assigned user in the JSS..."
			assignedUser=$(curl -v -u $API_Username:$API_Password https://$JSS_URL/JSSResource/computers/serialnumber/$computerSerialNumber/subset/location | xpath "/computer/location/username" 2>/dev/null | sed -e 's|<username>||g;s|</username>||g;')

			if [[ $assignedUser == "" ]]
			then
				echo "ERROR : No user is assigned to this device."
			else

				echo "Checking if the assigned user can unlock FileVault on this device..."
				userFileVaultEnabled=$(fdesetup list | awk -v usrN="$assignedUser" -F, 'index($0, usrN) {print $1}')
			
				if [[ $userFileVaultEnabled == "$assignedUser" ]]
				then
					echo "<result>This user can unlock FileVault.</result>"
				else
					echo "<result>This user cannot unlock FileVault.</result>"
				fi
			fi
		fi
	fi
fi
