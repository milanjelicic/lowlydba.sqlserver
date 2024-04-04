#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2024, Daniel Gutierrez (@gutizar)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: database_ag
short_description: Add/remove database to/from availability group
description:
  - Add or remove a database to/from a given availability group.
version_added: 0.4.0
options:
  database:
    description:
      - Name of the target database.
    type: str
    required: true
  availability_group:
    description:
      - Name of the availability group.
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
- name: Add database to availability group
  lowlydba.sqlserver.database_ag:
    sql_instance: sql-01.myco.io
    database: LowlyDB
    availability_group: AG01
    state: present
'''

RETURN = r'''
data:
  description:
    - A modified version of the output from the C(Add-DbaAgDatabase) or C(Remove-DbaAgDatabase) function.
  returned: success, but not in check_mode.
  type: dict
'''
