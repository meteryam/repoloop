#!/bin/bash
IFS=$'\n';

get_id () { egrep -v "^ID|NAME|---" | awk '{print $1}'; };
strip () { awk -F":" '{print $2":"$3":"$4}' | sed 's/^[ \t]*//;s/[ \t]*$//'; };

# for each organization

for MYORGID in `hammer organization list | get_id`; do

    # generate a list of repository sets

    MYREPOSETLIST=`hammer repository-set list --organization-id $MYORGID | grep yum | get_id`;

    # loop through that list

    for MYREPOSETID in `echo -e "$MYREPOSETLIST"`; do

        REPOSETINFO=`hammer repository-set info --organization-id $MYORGID --id $MYREPOSETID | egrep "ID:|Name:|^Label:"`;

        # get the first repository ID

        FIRSTREPOID=""
        FIRSTREPOID=`echo -e "$REPOSETINFO" | egrep -v "^ID:" | grep ID: | awk '{print $NF}' | sort -n | head -1`;

        # if no repository ID numbers, then just move on to the next repository set ID
        if [ "$FIRSTREPOID" != "" ]; then

            # get the label

            REPOSETLABEL=`echo -e "$REPOSETINFO" | egrep -v "^ID:" | grep ^Label: | strip`;

            # get the updated date

            REPOUPDATED=`hammer repository info --organization-id $MYORGID --id $FIRSTREPOID | egrep "^Name:|^Updated:" | grep ^Updated: | strip`;

            # print csv output

            echo $REPOSETLABEL","$REPOUPDATED;

        fi;


    done;

done
