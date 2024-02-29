#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2022, John McCall (@lowlydba)
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
    - Output from the C(Add-DbaServerRoleMember) or C(Remove-DbaServerRoleMember) function.
  returned: success, but not in check_mode.
  type: dict
'''
