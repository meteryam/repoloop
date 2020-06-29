# repoloop

This script combines the last sync dates and times for each repository with the
repository label known to yum, for each organization.  If an argument is supplied, it will only print
the information for the supplied label.  Here are a couple of examples:

```
# repoloop.sh

# repoloop.sh rhel-7-server-dotnet-rpms
```

For Red Hat repositories, labels are pulled from the repository set information.  For non-Red Hat
repositories, labels are pulled from the repository information.  This maintains consistency with
what yum expects.

This script calls the "hammer" command that comes with Satellite 6 to provide information that may
be useful to Satellite administrators.

This script combines the last sync dates and times for each repository with the
repository label known to yum, for each organization.  If an argument is supplied, it will only print
the information for the supplied label.

For Red Hat repositories, labels are pulled from the repository set information.  For non-Red Hat
repositories, labels are pulled from the repository information.  This maintains consistency with
what yum expects.

The pre6.4_repoloop.sh script is run the same way and accomplishes the same goals, but is designed
to work on Satellite 6.2 and 6.3 systems.

The repoloop.sh script has been run without errors on these versions of Satellite:

- 6.7.0-7
- 6.6.1-1
- 6.5.3-1
- 6.4.4.2-1

The pre6.4_repoloop.sh script has been run without errors on these versions of Satellite:

- 6.3.5.2-1
- 6.2.16.1-1.0
