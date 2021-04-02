## 0.4.0
---
 * Migrante from CentOS 7 to Oracle Linux 8. CentOS 8 has been delivered as a stillborn child. Thanks Red Hat!
 * Migrate from ChefDK to CINC Workstation. Roughly the same reason as the CentOS -> Oracle Linux migration, but licence, rather than support related.
 * Reduce default VB_CPUS to 2.
 * Drop Rubocop and Foodcritic in favour of Cookstyle (does both). Matched the Cookstyle lint rules to Rubocop.
 * Updated cookbook dependencies to latest versions. Dropped sysctl as the functionality is now part of CINC Client.
