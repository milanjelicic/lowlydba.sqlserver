#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2024, Daniel Gutierrez (@gutizar)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: ag_synchronization
short_description: Adds a user to an existing database role
description:
  - Adds a user to an existing database role.
version_added: 0.4.0
options:
  availability_group:
    description:
      - The name of the availability group.
    type: str
    required: true
  exclude:
    description:
      - Exclude one or more objects from the synchronization.
    type: list
    required: false
  login:
    description:
      - List of logins to synchronize. All if left empty.
    type: list
    required: false
  exclude_login:
    description:
      - Exclude one or more logins from the synchronization.
    type: list
    required: false
  job:
    description:
      - List of jobs to synchronize. All if left empty.
    type: list
    required: false
  exclude_job:
    description:
      - Exclude one or more jobs from the synchronization.
    type: list
    required: false
author: "Daniel Gutierrez (@gutizar)"
requirements:
  - L(dbatools,https://www.powershellgallery.com/packages/dbatools/) PowerShell module
extends_documentation_fragment:
  - lowlydba.sqlserver.sql_credentials
  - lowlydba.sqlserver.attributes.check_mode
  - lowlydba.sqlserver.attributes.platform_win
  - lowlydba.sqlserver.state
'''

EXAMPLES = r'''
- name: Synchronice availability group
  lowlydba.sqlserver.ag_synchronization:
    availability_group: AG01
    login: dblogin1
    exclude:
      - SpConfigure
      - Credentials
      - CustomErrors
      - DatabaseMail
      - LinkedServers
      - SystemTriggers
      - DatabaseOwner
      - AgentCategory
      - AgentOperator
      - AgentAlert
      - AgentProxy
      - AgentSchedule
      - AgentJob
'''

RETURN = r'''
data:
  description:
    - Output from the C(Sync-DbaAvailabilityGroup) function.
  returned: success, but not in check_mode.
  type: dict
'''
