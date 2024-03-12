#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2024, Daniel Gutierrez (@gutizar)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: ag_failover
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
- name: Failover to secondary instance
  lowlydba.sqlserver.ag_failover:
    availability_group: AG01
'''

RETURN = r'''
data:
  description:
    - Output from the C(Invoke-DbaAgFailover) function.
  returned: success, but not in check_mode.
  type: dict
'''
