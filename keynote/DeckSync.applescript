-- Thin wrapper so this specific app (not /bin/bash generally) can be
-- granted Full Disk Access in System Settings, scoping the grant to just
-- this sync tool instead of every bash script on the system. `do shell
-- script` is one of the patterns macOS's TCC attributes to the calling
-- app rather than to /bin/sh, which is the whole point of this wrapper.
do shell script "/bin/bash '" & (POSIX path of (path to home folder)) & "Documents/Classes/Slides/theme-system/sync_slides_drive.sh'"
