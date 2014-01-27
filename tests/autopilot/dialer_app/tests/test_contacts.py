# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2014 Canonical
# Author: Omer Akram <omer.akram@canonical.com>
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Dialer App"""

from __future__ import absolute_import

from autopilot.matchers import Eventually
from autopilot.introspection import get_proxy_object_for_existing_process
from testtools.matchers import Equals
from ubuntuuitoolkit import emulators as toolkit_emulators

from dialer_app.tests import DialerAppTestCase

import os
import subprocess


class TestContacts(DialerAppTestCase):
    """Tests for the contacts panel."""

    db_file = "history.sqlite"
    local_db_dir = "dialer_app/data/"
    system_db_dir = "/usr/lib/python2.7/dist-packages/dialer_app/data/"

    if os.path.exists("../../src/dialer-app"):
        database = local_db_dir + db_file
    else:
        database = system_db_dir + db_file

    def setUp(self):
        subprocess.call(["pkill", "history-daemon"])
        os.environ["HISTORY_SQLITE_DBPATH"] = self.database
        subprocess.Popen(["history-daemon"], stdout=subprocess.PIPE,
            universal_newlines=True)

        super(TestContacts, self).setUp()

    def _set_testability_environment_variable(self):
        """Makes sure every app opened in the current environment loads
        the testability driver.

        """
        subprocess.call(
            [
                "/sbin/initctl",
                "set-env",
                "QT_LOAD_TESTABILITY=1"
            ]
        )

    def _get_app_pid(self, app):
        return int(subprocess.check_output(["pidof", app]).strip())

    def test_call_log_item_opens_messaging(self):
        """Ensure tapping on 'send text message' item of a call log opens
        the messaging app.

        """
        self._set_testability_environment_variable()
        self.main_view.switch_to_tab("callLogTab")
        history_item = self.app.select_single(objectName="historyDelegate0")
        self.pointing_device.click_object(history_item)
        
        self.assertThat(history_item.detailsShown, Eventually(Equals(True)))
        self.assertThat(history_item.animating, Eventually(Equals(False)))

        send_msg_button = self.app.select_single(objectName="logMessageButton")
        self.pointing_device.click_object(send_msg_button)

        msg_app = get_proxy_object_for_existing_process(
            self._get_app_pid("messaging-app"),
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase
            )

        self.assertThat(msg_app.main_view.visible, Eventually(Equals(True)))
