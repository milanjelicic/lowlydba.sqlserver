#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2022, John McCall (@lowlydba)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: hadr
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
author: "John McCall (@lowlydba)"
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
    - Output from the C(Add-DbaAgDatabase) or C(Remove-DbaAgDatabase) function.
  returned: success, but not in check_mode.
  type: dict
'''
