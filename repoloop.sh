#!/bin/bash

IFS=$'\n';
strip () { awk -F":" '{print $2":"$3":"$4}' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed s'/:://'g; };

#
# This script combines the last sync dates and times for each repository with the
# repository label known to yum, for each organization.  If an argument is supplied, it will only print
# the information for the supplied label.
#
# For Red Hat repositories, labels are pulled from the repository set information.  For non-Red Hat
# repositories, labels are pulled from the repository information.  This maintains consistency with
# what yum expects.
#





# loop through the organizations

for MYORGID in `hammer --no-headers organization list | awk '{print $1}'`; do

	# print the organization name
	echo \# organization `hammer --no-headers organization info --id $MYORGID | grep ^Name: | strip`;

	# get a list of repositories
	REPOLIST=`hammer --csv --no-headers repository list --organization-id $MYORGID | grep ',yum,' | grep ',http' | awk -F"," '{print $1","$2}' | sed 's/^[ \t]*//;s/[ \t]*$//'`;

	# get a list of repository sets
	REPOSETLIST=`hammer --csv --no-headers repository-set list --organization-id $MYORGID | grep ',yum,' | tr -d '(' | tr -d ')' | awk -F"," '{print $3","$1}'`;


	# loop through each line of the repository list
	for REPOLINE in $REPOLIST; do

		REPOID=`echo $REPOLINE | awk -F"," '{print $1}'`;
		REPNAME=`echo $REPOLINE | awk -F"," '{print $2}'`;

		# loop through each word of each line until x86_64 is found
		SEARCHTERM='';
		IFS=$' ';for EACHWORD in $REPNAME; do

			if [ "$EACHWORD" != "x86_64" ]; then
				SEARCHTERM=`echo $SEARCHTERM $EACHWORD`;
			else
				break;
			fi;

		done;IFS=$'\n';

		# get the repo label and sync date from the repository ID
		REPOINFO=`hammer repository info --id $REPOID`;
		REPOLABEL=`echo -e "$REPOINFO" | grep ^Label: | strip`;
		REPOSYNC=`echo -e "$REPOINFO" | grep ^Updated: | strip`;


		# grep the repository set list for the search term
		SHORTLIST=`echo -e "$REPOSETLIST" | grep "^$SEARCHTERM,"`;

		# for each result
		for MYREPOSET in $SHORTLIST; do

			REPOSETID=`echo $MYREPOSET | awk -F"," '{print $2}'`;

			# set the output label to the repo set label if not null
			REPOSETLABEL=`hammer repository-set info --id $REPOSETID --organization-id $MYORGID | grep ^Label: | strip`;
			if [ "$REPOSETLABEL" != "" ]; then REPOLABEL=$REPOSETLABEL; fi;


			# print results, unless an argument is given and the results don't match the argument
			if [ "$1" == "" ] || [ "`echo \"$REPOLABEL\" | grep -i $1`" ]; then

				echo $REPOLABEL","$REPOSYNC;

				# if an argument is given and matched then break
				if [ "$1" != "" ] && [ "`echo \"$REPOLABEL\" | grep -i $1`" ]; then break; fi;

			fi;

		done;

		# print results for custom yum repositories
                if [ "$SHORTLIST" == "" ]; then

                       # print results, unless an argument is given and the results don't match the argument
                        if [ "$1" == "" ] || [ "`echo \"$REPOLABEL\" | grep -i $1`" ]; then

                                echo $REPOLABEL","$REPOSYNC;

                                # if an argument is given and matched then break
                                if [ "$1" != "" ] && [ "`echo \"$REPOLABEL\" | grep -i $1`" ]; then break; fi;

                        fi;

                fi;

	done;
done
