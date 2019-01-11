#!/bin/bash
# Usage populate names.txt with "first,last,discipline,email,state,account" names on each line
# 	to create users

Debug=0
OrgUnit="field"
Gam="${HOME}/bin/gam/gam"
Awk=/usr/bin/awk
Date=`date +%Y%m%d`
LogFile="${HOME}/dev/projects/google/create_users/logs/${Date}_log.txt"
AddedFile="${HOME}/dev/projects/google/create_users/added/${Date}_added.txt"
NameFileDated="${HOME}/dev/projects/google/create_users/done/${Date}.txt"
NameFile="${HOME}/dev/projects/google/create_users/names.txt"
SignatureFile="${HOME}/dev/projects/google/create_users/signatures.txt"
SignatureTemplateFile="${HOME}/dev/projects/google/signature_template.html"
IFS=","

# FUNCTIONS
function getEmail() {
	TmpNameFirst=$1
	TmpNameLast=$2

	# Remove whitespace
	TmpNameFirst=`echo $TmpNameFirst | sed 's/ //g'`
	TmpNameLast=`echo $TmpNameLast | sed 's/ //g'`

	# Remove hyphens
	TmpNameFirst=`echo $TmpNameFirst | sed 's/-//g'`
	TmpNameLast=`echo $TmpNameLast | sed 's/-//g'`

	# Remove apostrophe
	TmpNameFirst=`echo $TmpNameFirst | sed "s/'//g"`
	TmpNameLast=`echo $TmpNameLast | sed "s/'//g"`

	# Remove period
	TmpNameFirst=`echo $TmpNameFirst | sed 's/\.//g'`
	TmpNameLast=`echo $TmpNameLast | sed 's/\.//g'`	

	Email=$(echo $TmpNameFirst | awk '{print tolower($0); }' ) 
	Email+="."$(echo $TmpNameLast | awk '{print tolower($0); }' ) 
	Email="${Email}@domain.com"

	echo $Email
}

#
# Create the user and set signature
#
function createUser() {
while read NameFirst NameLast Discipline OriginalEmail State Customer
do
	Name="$NameFirst $NameLast"
	Email=$(getEmail "$NameFirst" "$NameLast")
	echo $Name >> $LogFile
	echo $Email >> $LogFile
	echo $Name $Email $Disc1 $Disc2 $State $Customer >> $LogFile

	error=$($Gam create user $Email firstname "$NameFirst" lastname "$NameLast" password "$Email" nohash gal off org "$OrgUnit" changepassword on 2>&1 1>>$LogFile)

	if [ $? -eq 0 ]; then
		echo "$NameFirst,$NameLast,$Discipline,$OriginalEmail,$State,$Customer" >> $SignatureFile
		echo "$NameFirst,$NameLast,$Discipline,$OriginalEmail,$State,$Customer" >> $AddedFile
	else
		echo $error >> $LogFile
	fi

	sleep 2 

done < $NameFile
}

# 
# Add user properties
#
function addUserProps() {
while read NameFirst NameLast Discipline OriginalEmail State Customer
do
	Email=$(getEmail "$NameFirst" "$NameLast")

	if [ -n "$Discipline" ]; then
       		echo "ADD DISCIPLINE " >> $LogFile
		error=$($Gam update user $Email Field.Discipline multivalued $Discipline 2>&1 1>>$LogFile)

		if [ $? -ne 0 ]; then
			echo $error >> $LogFile
		fi
	fi

    # ADD STATE
    if [ -n "$State" ]; then
        echo "ADD STATE " >> $LogFile
        error=$($Gam update user $Email Field.State $State  2>&1 1>>$LogFile)
        if [ $? -ne 0 ]; then
            echo $error >> $LogFile
        fi
	fi

	# ADD CUSTOMER
	if [ -n "$Customer" ]; then
		echo "ADD CUSTOMER " >> $LogFile
		error=$($Gam update user $Email Field.Customer multivalued $Customer  2>&1 1>>$LogFile)
		if [ $? -ne 0 ]; then
			echo $error >> $LogFile
		fi
	fi

	# ADD CRMEMAIL
	if [ -n "$OriginalEmail" ]; then
		echo "ADD CRM EMAIL " >> $LogFile
		error=$($Gam update user $Email Field.CrmEmail $OriginalEmail  2>&1 1>>$LogFile)
		if [ $? -ne 0 ]; then
			echo $error >> $LogFile
		fi
	fi
	sleep 2

done < $NameFile
}


#
# Add discipline  groups to the user
#
function addDisciplineGroupsToUser() {
while read NameFirst NameLast Discipline OriginalEmail State Customer
do
	Email=$(getEmail "$NameFirst" "$NameLast")
	Group="list-${Discipline}"

	echo "$Email into docs-resources-all" >> $LogFile
	error=$($Gam update group "docs-resources-all" add member $Email 2>&1 1>>$LogFile)
	if [ $? -ne 0 ]; then
		echo $error >> $LogFile
	fi

	echo "$Email into $Group" >> $LogFile
	error=$($Gam update group $Group add member $Email 2>&1 1>>$LogFile)
	if [ $? -ne 0 ]; then
		echo $error >> $LogFile
	fi

    if [ "$Discipline" = "CF" ]; then
   		echo "$Email into list-slp" >> $LogFile
    	error=$($Gam update group "list-slp" add member $Email 2>&1 1>>$LogFile)
    	if [ $? -ne 0 ]; then
    		echo $error >> $LogFile
		fi
	fi

	if [ "$Discipline" = "SLPA" ]; then
		echo "$Email into list-slp" >> $LogFile
		error=$($Gam update group "list-slp" add member $Email 2>&1 1>>$LogFile)
		if [ $? -ne 0 ]; then
			echo $error >> $LogFile
		fi
	fi

	if [ "$Discipline" = "PTA" ]; then
		echo "$Email into list-pt" >> $LogFile
		error=$($Gam update group "list-pt" add member $Email 2>&1 1>>$LogFile)
		if [ $? -ne 0 ]; then
			echo $error >> $LogFile
		fi
	fi

	if [ "$Discipline" = "OTA" ]; then
		echo "$Email into list-ot" >> $LogFile
		error=$($Gam update group "list-ot" add member $Email 2>&1 1>>$LogFile)
		if [ $? -ne 0 ]; then
			echo $error >> $LogFile
		fi
	fi
	
	sleep 2
done < $NameFile
}


# 
# Set Signature
#
function setSignature() {
while read NameFirst NameLast Discipline OriginalEmail State Customer
do
	echo "Setting signatures..." >> $LogFile

	Email=$(getEmail "$NameFirst" "$NameLast")
	Name="$NameFirst $NameLast"

	echo "Setting signature for $Email" >> $LogFile
	TemplateText=$(<$SignatureTemplateFile)
	SignatureHtml="${TemplateText/XXX/$Name}"
  		
	error=$($Gam user $Email signature "${SignatureHtml}" 2>&1 1>>$LogFile)
	if [ $? -eq 0 ]; then
		echo ""
  	else
   		echo $error >> $LogFile
  	fi

	sleep 2
done < $SignatureFile
}


if [ $Debug -eq 1 ]; then
	OrgUnit="testing"
fi

echo 'Start...'
echo 'Start...' >> $LogFile

# Reset signature file
> $SignatureFile

# snapshot the names file
cat $NameFile >> $NameFileDated
echo "\r\n" >> $NameFileDated

createUser
sleep 15
addUserProps
sleep 15
addDisciplineGroupsToUser
sleep 15
setSignature

echo 'Finish...' >> $LogFile
echo 'Finish...';


