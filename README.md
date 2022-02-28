## SFCC Log & Source Files Analysis

Repo contains currently only one bash script (should run in Windows in git bash shell) to extract log entries specific to a session or customer number.

```
USAGE: bash scripts/get_sorted_logs_for_customer_n_date.sh <Logs-root-dir> any:<string>|sess:<Session-ID> <Date>
```

1. `scripts/get_sorted_logs_for_customer_n_date.sh` expects it to be run from the root of this folder.
1. Date has to be specified as one of the input params, since it avoids searching all files and there could be 1000s of them.

Example script usages:

1. `scripts/get_sorted_logs_for_customer_n_date.sh any:74D958E9-D682-49AB-BF7E-3F1943EA53BC 20220126`
1. `scripts/get_sorted_logs_for_customer_n_date.sh sess:ZIk5xwdgdR 20220220`
1. `scripts/get_sorted_logs_for_customer_n_date.sh  "any: some other string with spaces" 20220215`
### Notes

1. Customer number based search for session works only if there are records with customer number in header.

### TODOs

- [x] Allow any string to be searched in the log record header to get session ID
- [ ] If the session log records spills-over to the next date (from the input date), they have to be included.
- [ ] Create a separate script to check for new log errors since the last code version.
    * This will be useful in getting a catalog of existing errors.
    * By comparing with existing errors, we can check if new errors are introduced in latest software release.
    * One can also know if any of the older errors are fixed in latest software release.
- [ ] How can we build it as a extension to VS-Code to be used by developers?

