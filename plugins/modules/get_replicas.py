#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2024, Milan Jelicic (@milanjelicic)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: get_replicas
short_description: Get AG replicas
description:
  - Get information about availability group replicas in a SQL Server Always On AG.
version_added: 2.3.0
options:
  sql_instance:
    description:
      - The SQL Server instance to lookup.
    type: str
    required: true
  availability_group:
    description:
      - Name of the Availability Group to lookup.
    type: str
    required: true
  username:
    description:
      - Username for alternative credential to authenticate with Windows.
    type: str
    required: false
  password:
    description:
      - Password for alternative credential to authenticate with Windows.
    type: str
    required: false
author: "Milan Jelicic (@milanjelicic)"
requirements:
  - L(dbatools,https://www.powershellgallery.com/packages/dbatools/) PowerShell module
extends_documentation_fragment:
  - lowlydba.sqlserver.sql_credentials
  - lowlydba.sqlserver.attributes.check_mode
  - lowlydba.sqlserver.attributes.platform_win
'''

EXAMPLES = r'''
- name: Get AG replicas
  lowlydba.sqlserver.get_replicas:
    sql_instance: 'sql-01.myco.io'
    sql_username: 'sa'
    sql_password: 'password'
    ag_name: 'AG01'
'''

RETURN = r'''
data:
  description:
    - Availability Replicas from the C(Get-DbaAvailabilityGroup) function.
  returned: success, but not in check_mode.
  type: list
'''
