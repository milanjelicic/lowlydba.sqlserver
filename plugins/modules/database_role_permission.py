#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2024, Daniel Gutierrez (@gutizar)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: database_role_permission
short_description: Modifies the permissions for a database role
description:
  - Modifies the permissions for a database role.
version_added: 0.4.0
options:
  database:
    description:
      - Name of the target database.
    type: str
    required: true
  role_name:
    description:
      - Name of the server role.
    type: str
    required: true
  permission:
    description:
      - Name of the permission to modify.
    type: str
    required: true
  action:
    description:
      - Action to permform on the permission. Either grant, deny or revoke.
    type: str
    required: false
    default: grant
author: "Daniel Gutierrez (@gutizar)"
requirements:
  - L(dbatools,https://www.powershellgallery.com/packages/dbatools/) PowerShell module
extends_documentation_fragment:
  - lowlydba.sqlserver.sql_credentials
  - lowlydba.sqlserver.attributes.platform_win
'''

EXAMPLES = r'''
- name: Grant ALTER to role mydbrole
  lowlydba.sqlserver.database_role_permission:
    sql_instance: sql-01.myco.io
    database: LOWLYDB
    role_name: mydbrole
    action: grant
'''

RETURN = r''''''
