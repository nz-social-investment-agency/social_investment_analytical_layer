Readme file for folder: SIAL_bqa_complete

All scripts in this folder have been reviewed by the corresponding agency.

Where possible the scripts are written in SQL and create views to conserve space. 
Users should take care using tables during a refresh persiod as views will use the latest data.
Where more complex code to create tables were required SAS is used and tables (not views) are created.

All views and tables follow the naming convention SIAL_(capital case three digit org code)_(description)_events. 
For example SIAL_CYF_abuse_events or SIAL_MOJ_courtcase_events. No table or view names exceed 32 characters 
(this is the max column name length in SAS).

All script names follow the same naming conventions without the proceeding SIAL_.

Dependencies are saved in the SIAL dependencies folder. Note this data is not a confidentiality breach and
is does not identify any person. The data relates to cost look ups. These have either been sourced directly 
from an agency, or freely online (treasury vote information). Where sourced from an agency the SIU has been
granted premission to share it for use in these tables.

For any questions please contact info@siu.govt.nz.

Last updated: Jan 2017.
