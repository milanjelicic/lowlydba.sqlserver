#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2024, Daniel Gutierrez (@gutizar)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: server_role_member
short_description: Adds a login to an existing server role
description:
  - Adds a login to an existing server role.
version_added: 0.4.0
options:
  role_name:
    description:
      - Name of the server role.
    type: str
    required: true
  login_name:
    description:
      - Name of the login to be added to the server role.
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
- name: Create server role
  lowlydba.sqlserver.server_role_member:
    sql_instance: sql-01.myco.io
    role_name: myrole
    login_name: mylogin
    state: present
'''

RETURN = r'''
data:
  description:
    - A dictionary object with information on the modified role.
    - Properties:
      - Members: updated list of server logins who are members of this role.
      - Role: name of the server role.
  returned: success, but not in check_mode.
  type: dict
'''
