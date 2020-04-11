# repoloop

This script calls the "hammer" command that comes with Satellite 6 to provide information that may
be useful to Satellite administrators.

This script combines the last sync dates and times for each repository with the
repository label known to yum, for each organization.  If an argument is supplied, it will only print
the information for the supplied label.

For Red Hat repositories, labels are pulled from the repository set information.  For non-Red Hat
repositories, labels are pulled from the repository information.  This maintains consistency with
what yum expects.

This script has been run without errors on these versions of Satellite:

6.5.3-1
