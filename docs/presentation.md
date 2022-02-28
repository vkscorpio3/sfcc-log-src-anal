---
title: SFCC Log Files Analysis
theme: solarized
revealOptions:
  transition: 'None'
  width: 1280
  height: 720
---

# SFCC Log Files Analysis

Presenter: Appan

Date: 28 Feb, 2022


## Agenda

* Webdav Logs Folder & Files
    * Log Types & File Naming Convention
    * Log Files Retention & Other Limits
    * Log Record Structure
* Other Log Files
* Scenario: Checkout Scenario
* Demo - Setup & Filter & Merge Script
* Resources & What Next ?


### Webdav Logs Folder Structure

<div class="twocolumn">

<div id="left">

![Webdav folders](imgs/webdav_logs_struct.png)

</div>

<div id="right" data-markdown>

* `Logs/` - both sub-directories & log files
* `log_archive/` - older log files in gzip format
* `jobs/<specific-job>/` - job specific 
* `codeprofiler` - CSV files of the profiler runtime data
* `SecurityLogs` - security specific log files
* `notification/` - bucket text files
</div>
</div>

##^ Log Types & File Naming Convention

* Log File Name: `<log-type>-ecom-sandbox-<instance>-app-7574cb5d64-lcf5t-0-appserver-<date>.log[.gz]`

notification/unbucketed-marykayintouch-ph.txt


##^ Log Files Retention & Other Limits

* Top-level `Logs` folder: 
* `.last_cleanup` file updated with timestamp after a cleanup

##^ Special Platform Log Entries

* Maximum log file size limit has reached
* Repeat log records ignored log entry

![Max log file size](imgs/log_file_max_size_sample.png)

### Log Record Structure

![Log record samples](imgs/log_rec_samples.png)

### Security & Code Profiler Log

<div id='left' data-markdown>

* Security logs:
    - Business manager ACL actions
    - Business Manager Pipeline
    - Login & Logout actions - `[DW-SEC]`
    - User role assignments & removals
    - CSRF token related

</div>
<div id="right" data-markdown>

* Code Profiler Logs:
    - Generated every one-hour
    - Controller run-times: 
       * Count, Total Time, OwnTime
       * Total wait-time, Own wait-time
    - Types: 
       * ISML, ON_REQUEST, SF_PAGE,
       * PIPELINE_NODE, SCRIPT_CONTROLLER
       * REST_DATA,SCRIPT_HOOK,SCRIPT_API

</div>

### Root-Cause Analysis

* 

## Demo of the Filter & Merge Script

* Install `rclone` binary file
* Setup `.config/rclone/rclone.conf` for each instance
* Use rclone to download the log files using webdav
* 


### Best Practices & Resources

1. Proper choice of log levels & category
    * Using DEBUG instead of INFO
    * Do not use root logger
    * Create log category - upto 3 levels
1. SFCC Documentation [Log Files](https://documentation.b2c.commercecloud.salesforce.com/DOC1/topic/com.demandware.dochelp/content/b2c_commerce/topics/site_development/b2c_log_files_overview.html)
1. `rclone` [download link](https://rclone.org/downloads/)

### What Next ?

* Enhancements to filter & merge script
    - Using customer uuid as input
    - Enable / Disable job logs
* DevOps & Log Analysis
    - Finding new log entries compared to previous