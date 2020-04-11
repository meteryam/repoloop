#!/bin/bash

#
# This script combines the last sync dates and times for each repository with the
# repository label known to yum, for each organization.  If an argument is supplied, it will only print
# the information for the supplied label.
#
# For Red Hat repositories, labels are pulled from the repository set information.  For non-Red Hat
# repositories, labels are pulled from the repository information.  This maintains consistency with
# what yum expects.
#

IFS=$'\n';

# The "strip" function allows us to get the second column from a "hammer ... info" output.  Including multiple fields
# in the awk term allows us to cleanly include timestamps from the "Updated:" line, while the last "sed" term removes
# the extra colons that appear when we apply that awk term to lines that don't include dates.  This allows us to use
# one filter for many cases.

strip () { awk -F":" '{print $2":"$3":"$4}' | sed s'/:://'g | sed 's/^[ \t]*//;s/[ \t]*$//'; };


# The "no_header" function strips off the header and vertical bars.  This is a substitute for the
# "--no-headers" option in versions of Satellite older than 6.4.

no_header () { egrep -v "NAME|^ID|---"; };


# fail immediately if hammer fails

false | hammer organization list 1>/dev/null
if [ "$?" != 0 ]; then
    echo problem running hammer commands. quitting.;
    exit;
fi;

# loop through the organizations
for MYORGID in `hammer organization list | no_header | awk '{print $1}'`; do

    # print the organization name
    echo \# organization `hammer organization info --id $MYORGID | no_header | grep ^Name: | strip`;

    # get a list of repositories
    REPOLIST=`hammer --csv repository list --organization-id $MYORGID 2>/dev/null | no_header | grep ',yum,' | awk -F"," '{print $1","$2}' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s/.*/&,$PRODUCTID/"`;

    # in Satellite versions older than 6.4, the repository-set list command requires a product
    SEARCHLIST='';
    for PRODUCTID in `hammer product list --organization-id $MYORGID | no_header | awk '{print $1}'`; do

    	# In the lines below, we have to strip out the parentheses for naming convention compatibility.  Repository sets
    	# enclose some information (eg "(RPMs)") within parentheses, but repository names don't.  Moreover, repository
    	# set names use parentheses in complex ways.  Eliminating them from consideration doesn't seem to produce
    	# duplicate results, but it does eliminate a lot of string-handling logic.

    	# get a list of repository sets
        # re-ordering the fields makes grepping easier later on
        REPOSETLIST=`hammer --csv repository-set list --organization-id $MYORGID --product-id $PRODUCTID 2>/dev/null | no_header | egrep ',yum,|,kickstart,' | tr -d '(' | tr -d ')' | awk -F"," '{print $3","$1}'`;

        # we need a list of all repository sets to report on custom repos
        ALLREPOSETS=`echo -e "$ALLREPOSETS"\n"$REPOSETLIST"`;

    	# loop through each line of the repository list
    	for REPOLINE in $REPOLIST; do

    		REPOID=`echo $REPOLINE | awk -F"," '{print $1}'`;
    		REPONAME=`echo $REPOLINE | awk -F"," '{print $2}'`;

    		# We only want to include the value of each line up to (but not including) the platform information.
    		# While that information is included in the repository name, it isn't included in the repository
    		# set information, which could include multiple platforms.  This means that we have to strip out
    		# not only the hardware platform (eg "x86_64"), but also the OS platform (eg "7Server", "7.1Server", etc).

    		# loop through each word of each line until x86_64 is found
    		SEARCHTERM='';
    		IFS=$' ';for EACHWORD in $REPONAME; do

    			if [ "$EACHWORD" == "x86_64" ] || [ "$EACHWORD" == "i386" ] || [ "$EACHWORD" == "i686" ] || [ "$EACHWORD" == "ia64" ] || [ "$EACHWORD" == "s390x" ]; then
    				break;
    			else
    				SEARCHTERM=`echo $SEARCHTERM $EACHWORD`;
    			fi;

    		done;IFS=$'\n';

            # building this now will make the custom repo search faster
            SEARCHLIST=`echo -e "$SEARCHLIST""\n""$REPOID","$SEARCHTERM"`;

    		# grep the repository set list for the search term
    		SHORTLIST=`echo -e "$REPOSETLIST" | grep "^$SEARCHTERM,"`;

    		# get the repo label and sync date from the repository ID
    		REPOINFO=`hammer repository info --id $REPOID 2>/dev/null`;
    		REPOLABEL=`echo -e "$REPOINFO" | grep ^Label: | strip`;

            # make sure we only report updated times for synced repos
            if [ "`echo -e "$REPOINFO" | grep Success`" ]; then
                REPOSYNC=`echo -e "$REPOINFO" | grep "Last Sync Date:" | strip`;
            else
                REPOSYNC=`echo -e "$REPOINFO" | grep Status: | strip`;
            fi;

            SHORTLIST=`echo -e "$SHORTLIST" | sort -u`;

    		# print results for custom yum repositories
            if [ "$SHORTLIST" ]; then

        		# for each result; this will work only for repositories imported via manifest
        		for MYREPOSET in $SHORTLIST; do

        			REPOSETID=`echo $MYREPOSET | awk -F"," '{print $2}'`;

        			# set the output label to the repo set label if not null
        			REPOSETLABEL=`hammer repository-set info --organization-id $MYORGID --product-id $PRODUCTID --id $REPOSETID 2>/dev/null | grep ^Label: | strip`;

        			# non-Red Hat repositories don't have repo set labels
        			if [ "$REPOSETLABEL" == "" ]; then REPOSETLABEL=$REPOLABEL; fi;


        			# print results, unless an argument is given and the results don't match the argument
        			if [ "$1" == "" ] || [ "`echo \"$REPOLABEL\" | grep -i $1`" ]; then

        				echo $REPOSETLABEL","$REPOLABEL","$REPOSYNC;

        				# if an argument is given and matched then break
        				if [ "$1" != "" ] && [ "`echo \"$REPOLABEL\" | grep -i $1`" ]; then break; fi;

        			fi;

        		done;

            fi;

    	done;

    done;

    SEARCHLIST=`echo -e "$SEARCHLIST" | sort -u`;

    # print values for custom repositories, which won't show up in the repository set list
    # loop through each line of the repository list
    for REPOLINE in $SEARCHLIST; do

    	REPOID=`echo $REPOLINE | awk -F"," '{print $1}'`;
    	REPONAME=`echo $REPOLINE | awk -F"," '{print $2}'`;

		# grep the repository set list for the search term
		SHORTLIST=`echo -e "$ALLREPOSETS" | grep "^$REPONAME,"`;

    	# print results for custom yum repositories, which won't show up in the repository set list
        if [ "$SHORTLIST" == "" ]; then

        	# get the repo label and sync date from the repository ID
        	REPOINFO=`hammer repository info --id $REPOID`;
        	REPOLABEL=`echo -e "$REPOINFO" | grep ^Label: | strip`;

            # make sure we only report updated times for synced repos
            if [ "`echo -e "$REPOINFO" | grep Success`" ]; then
                REPOSYNC=`echo -e "$REPOINFO" | grep "Last Sync Date:" | strip`;
            else
                REPOSYNC=`echo -e "$REPOINFO" | grep Status: | strip`;
            fi;

            # print results, unless an argument is given and the results don't match the argument
            echo $REPOLABEL","$REPOLABEL","$REPOSYNC;

            # if an argument is given and matched then break
            if [ "$1" != "" ] && [ "`echo \"$REPOLABEL\" | grep -i $1`" ]; then break; fi;

        fi;

    done;

done

