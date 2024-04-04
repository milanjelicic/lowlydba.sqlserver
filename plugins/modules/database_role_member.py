#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2024, Daniel Gutierrez (@gutizar)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: database_role_member
short_description: Adds a user to an existing database role
description:
  - Adds a user to an existing database role.
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
  user_name:
    description:
      - Database user to be added to the role.
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
- name: Add user to database role
  lowlydba.sqlserver.database_role_member:
    sql_instance: sql-01.myco.io
    database: LOWLYDB
    role_name: mydbrole
    login_name: myuser
    state: present
'''

RETURN = r'''
data:
  description:
    - A dictionary object with information on the modified role.
    - Properties:
      - database: name of the database.
      - members: updated list of database users who are members of this role.
      - role: name of the database role.
  returned: success, but not in check_mode.
  type: dict
'''
