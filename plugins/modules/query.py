#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2024, Daniel Gutierrez (@gutizar)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: query
short_description: Executes a generic query
description:
  - Execute a query against a database. Does not return a resultset. Ideal for ad-hoc configurations or DML queries.
version_added: 0.1.0
options:
  database:
    description:
      - Name of the database to execute the query in.
    type: str
    required: true
  query:
    description:
      - The query to be executed.
    type: str
    required: true
  query_timeout:
    description:
      - Number of seconds to wait before timing out the query execution.
    type: int
    required: false
    default: 60
  messages_to_output:
    description:
      - Add output stream messages to the result object.
    type: bool
    required: false
    default: false
author: "Daniel Gutierrez (@gutizar)"
requirements:
  - L(dbatools,https://www.powershellgallery.com/packages/dbatools/) PowerShell module
extends_documentation_fragment:
  - lowlydba.sqlserver.sql_credentials
  - lowlydba.sqlserver.attributes.check_mode
  - lowlydba.sqlserver.attributes.platform_all
'''

EXAMPLES = r'''
- name: Select all users
  lowlydba.sqlserver.query:
    sql_instance: sql-01-myco.io
    database: userdb
    query: "SELECT * FROM dbo.User;"
'''

RETURN = r'''
data:
  description:
    - Modified output from the C(Invoke-DbaQuery) function.
    - Properties:
      - results: the result of the query as a list of dictionaries.
      - messages: list of output messages.
      - completion_time: time when the query was completed.
  returned: success, but not in check_mode.
  type: dict
'''
