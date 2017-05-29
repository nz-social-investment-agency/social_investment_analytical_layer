# Change Log

all notable changes to this project will be documented in this file

## [1.0.0] - Jan 2017

v1

## [1.1.0] - May 2017
* Business QA completed for several MOE tables, Corrections and Police. These scripts have now been shifted into the bqa_complete folder
* New SIAL tables for HNZ and Industry Training and Early Childhood Education
* Rewrite of the mortality script due to the IDI mortality table being split in two.
* Tertiary table (now view) ported over to SQL
* New feature to enable the SIAL components to be pointed to any refresh version of the IDI_Clean DB (provided that all source tables required by the SIAL views are available in that refresh)
* IDI_Clean.moh_clean.mortality_registrations table structure has changed since the latest IDI refresh. The latest SIAL script has been modified to accomodate for this change. What this means is that if the SIAL is repointed to IDI_Clean_20161020, then the script 'MIX_mortality_events.sql' is bound to fail. You will need to obtain the earlier version of this SIAL script from Github and replace the new script with the older version.




