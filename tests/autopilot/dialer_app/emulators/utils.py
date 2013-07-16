# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

class Utils(object):
    """Utility functions to write tests for dialer-app"""

    def __init__(self, app):
        self.app = app

    def get_tool_bar(self):
        """Returns the toolbar in the main events view."""
        return self.app.select_single("Toolbar")

    def get_tool_button(self, name):
        """Returns the toolbar button named `name`"""
        return self.app.select_single("ActionItem", objectName=name)

    def get_conversations_tab_button(self):
        return self.app.select_single("AbstractButton", buttonIndex=4)

    def get_contacts_tab_button(self):
        return self.app.select_single("AbstractButton", buttonIndex=5)

    def get_conversations_pane(self):
        return self.app.select_single(
            "Tab", objectName="communicationsTab")

    def get_contacts_pane(self):
        return self.app.select_single("Tab", objectName="contactsTab")
