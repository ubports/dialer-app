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
import time


class TestCallLogs(DialerAppTestCase):
    """Tests for the call log panel."""

    db_file = "history.sqlite"
    local_db_dir = "dialer_app/data/"
    system_db_dir = "/usr/lib/python2.7/dist-packages/dialer_app/data/"
    devnull = open(os.devnull, 'w')
    app_to_kill = ""

    if os.path.exists("../../src/dialer-app"):
        database = local_db_dir + db_file
    else:
        database = system_db_dir + db_file

    def setUp(self):
        subprocess.call(["pkill", "history-daemon"])
        os.environ["HISTORY_SQLITE_DBPATH"] = self.database
        subprocess.Popen(["history-daemon"], stderr=self.devnull)

        super(TestCallLogs, self).setUp()

        self._set_testability_environment_variable()
        self.main_view.switch_to_tab("callLogTab")

    def tearDown(self):
        super(TestCallLogs, self).tearDown()
        subprocess.call(["pkill", self.app_to_kill])

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
        for i in range(10):
            try:
                return int(subprocess.check_output(["pidof", app]).strip())
            except subprocess.CalledProcessError:
                # application not started yet, check in a second
                time.sleep(1)

    def _get_app_proxy_object(self, app_name):
        return get_proxy_object_for_existing_process(
            self._get_app_pid(app_name),
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase
        )

    def test_call_log_item_opens_messaging(self):
        """Ensure tapping on 'send text message' item of a call log opens
        the messaging app.

        """
        history_item = self.main_view.get_first_log()
        self.pointing_device.click_object(history_item)
        
        self.assertThat(history_item.detailsShown, Eventually(Equals(True)))
        self.assertThat(history_item.animating, Eventually(Equals(False)))

        send_msg_button = self.app.select_single(objectName="logMessageButton")
        self.pointing_device.click_object(send_msg_button)

        msg_app = self._get_app_proxy_object("messaging-app")
        msg_app_view = msg_app.select_single("QQuickView")
        msgs_pane = msg_app.select_single(objectName="messagesPage")

        # name of the app that we expect to be started on clicking the log
        # item, so that we can kill it
        self.app_to_kill = "messaging-app"
        
        self.assertThat(msg_app_view.visible, Eventually(Equals(True)))
        self.assertThat(msgs_pane.visible, Eventually(Equals(True)))
