#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2024, Daniel Gutierrez (@gutizar)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: server_role
short_description: Creates a server role
description:
  - Creates a server role.
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
- name: Add login to server role
  lowlydba.sqlserver.server_role:
    sql_instance: sql-01.myco.io
    role_name: myrole
    state: present
'''

RETURN = r'''
data:
  description:
    - Output from the C(Add-DbaServerRole) or C(Remove-DbaServerRole) function.
  returned: success, but not in check_mode.
  type: dict
'''
