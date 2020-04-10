# repoloop

This script combines the last sync dates and times for each repository with the
repository label known to yum, for each organization.  If an argument is supplied, it will only print
the information for the supplied label.

For Red Hat repositories, labels are pulled from the repository set information.  For non-Red Hat
repositories, labels are pulled from the repository information.  This maintains consistency with
what yum expects.
