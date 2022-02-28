## SFCC Log & Source Files Analysis

Repo contains currently only one bash script (should run in Windows in git bash shell) to extract log entries specific to a session or customer number.

```
USAGE: bash scripts/get_sorted_logs_for_customer_n_date.sh <Logs-root-dir> custno:<Customer-no>|sess:<Session-ID> <Date>
```
Date has to be specified as one of the input params, since it avoids searching all files and there can be 1000s of them.

### Notes

1. Customer number based search for session works only if there are records with customer number in header.

### TODOs

- [ ] - Create a separate script to check for new log errors since the last code version.
- [ ] - How can be build it as a extension to VS-Code to be used by developers?
- [ ] - If the session log records spills-over to the next date (from the input date), they have to be included.

