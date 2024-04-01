#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2024, Daniel Gutierrez (@gutizar)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: database_role
short_description: Creates a database role
description:
  - Creates a database role.
version_added: 0.4.0
options:
  database:
    description:
      - Name of the target database.
    type: str
    required: true
  role_name:
    description:
      - Name of the database role.
    type: str
    required: true
  owner_name:
    description:
      - Owner of the role.
    type: str
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
- name: Add database role
  lowlydba.sqlserver.database_role:
    sql_instance: sql-01.myco.io
    database: LOWLYDB
    role_name: mydbrole
    state: present
'''

RETURN = r'''
data:
  description:
    - Output from the C(New-DbaDbRole) or C(Remove-DbaDbRole) function.
  returned: success, but not in check_mode.
  type: dict
'''
