# launchd Property List Manual

This manual contains description of some of the most used XML property list keys. For more check the documentation (man pages).
https://www.manpagez.com/man/5/launchd.plist/

## NAME

`launchd.plist` -- System wide and per-user daemon/agent configuration files

## DESCRIPTION

This document details the parameters that can be given to an XML property list that can be loaded into launchd with launchctl.

## XML PROPERTY LIST KEYS

### Label `<string>`

This required key uniquely identifies the job to launchd.
     
### ProgramArguments `<array of strings>`

This key maps to the second argument of `execvp(3)`. This key is required in the absence of the Program key. Please note: many people are confused by this key. Please read execvp(3) very carefully!

### Disabled `<boolean>`

This optional key is used as a hint to `launchctl(1)` that it should not submit this job to launchd when loading a job or jobs. The value of this key does NOT reflect the current state of the job on the running system. If you wish to know whether a job is loaded in launchd, reading this key from a configuration file yourself is not a sufficient test. You should query launchd for the presence of the job using the `launchctl(1)` list subcommand or use the ServiceManagement framework's `SMJobCopyDictionary()` method.

Note that as of `Mac OS X v10.6`, this key's value in a configuration file conveys a default value, which is changed with the `[-w]` option of the `launchctl(1)` load and unload subcommands. These subcommands no longer modify the configuration file, so the value displayed in the configuration file is not necessarily the value that `launchctl(1)` will apply. See `launchctl(1)` for more information.

Please also be mindful that you should only use this key if the provided on-demand and KeepAlive criteria are insufficient to describe the conditions under which your job needs to run. The cost to have a job loaded in launchd is negligible, so there is no harm in loading a job which only runs once or very rarely.
     
### LimitLoadToSessionType `<string>`

This configuration file only applies to sessions of the type specified. This key is used in concert with the `-S` flag to launchctl.
     
### KeepAlive `<boolean or dictionary of stuff>`

This optional key is used to control whether your job is to be kept con- tinuously running or to let demand and conditions control the invocation. The default is false and therefore only demand will start the job. The value may be set to true to unconditionally keep the job alive. Alternatively, a dictionary of conditions may be specified to selectively con trol whether launchd keeps a job alive or not. If multiple keys are pro vided, launchd ORs them, thus providing maximum flexibility to the job to refine the logic and stall if necessary. If launchd finds no restart the job, it falls back on demand based invocation. Jobs that exit quickly and frequently when configured to be kept alive will be throttled to converve system resources.

* SuccessfulExit `<boolean>`</br>
If true, the job will be restarted as long as the program exits and with an exit status of zero. If false, the job will be restarted in the inverse condition. This key implies that `"RunAtLoad"` is set to true, since the job needs to run at least once before we can get an exit status.

* NetworkState `<boolean>`</br>
If true, the job will be kept alive as long as the network is up, where up is defined as at least one non-loopback interface being up and having IPv4 or IPv6 addresses assigned to them. If false, the job will be kept alive in the inverse condition.

* PathState `<dictionary of booleans>`</br>
Each key in this dictionary is a file-system path. If the value of the key is true, then the job will be kept alive as long as the path exists. If false, the job will be kept alive in the inverse condition. The intent of this feature is that two or more jobs may create semaphores in the file-system namespace.

* OtherJobEnabled `<dictionary of booleans>`</br>
Each key in this dictionary is the label of another job. If the value of the key is true, then this job is kept alive as long as that other job is enabled. Otherwise, if the value is false, then this job is kept alive as long as the other job is disabled. This feature should not be considered a substitute for the use of IPC.
 
### RunAtLoad `<boolean>`

This optional key is used to control whether your job is launched once at the time the job is loaded. The default is false.
     
### TimeOut `<integer>`

The recommended idle time out (in seconds) to pass to the job. If no value is specified, a default time out will be supplied by launchd for use by the job at check in time.
