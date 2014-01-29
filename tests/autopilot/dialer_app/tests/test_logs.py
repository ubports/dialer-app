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
import fixtures


class TestabilityEnvironment(fixtures.Fixture):

    def setUp(self):
        super(TestabilityEnvironment, self).setUp()
        self._set_testability_environment_variable()
        self.addCleanup(self._reset_environment_variable)

    def _set_testability_environment_variable(self):
        """Make sure every app loads the testability driver."""
        subprocess.call(
            [
                '/sbin/initctl',
                'set-env',
                '--global',
                'QT_LOAD_TESTABILITY=1'
            ]
        )

    def _reset_environment_variable(self):
        """Resets the previously added env variable."""
        subprocess.call(
            [
                '/sbin/initctl',
                'unset-env',
                'QT_LOAD_TESTABILITY'
            ]
        )


class TestCallLogs(DialerAppTestCase):
    """Tests for the call log panel."""

    db_file = 'history.sqlite'
    local_db_dir = 'dialer_app/data/'
    system_db_dir = '/usr/lib/python2.7/dist-packages/dialer_app/data/'
    devnull = open(os.devnull, 'w')

    def setUp(self):
        if os.path.exists('../../src/dialer-app'):
            database = self.local_db_dir + self.db_file
        else:
            database = self.system_db_dir + self.db_file
        
        subprocess.call(['pkill', 'history-daemon'])
        os.environ['HISTORY_SQLITE_DBPATH'] = database
        subprocess.Popen(['history-daemon'], stderr=self.devnull)

        super(TestCallLogs, self).setUp()
        testability_environment = TestabilityEnvironment()
        self.useFixture(testability_environment)
        self.main_view.switch_to_tab('callLogTab')

    def _get_app_pid(self, app):
        for i in range(10):
            try:
                return int(subprocess.check_output(['pidof', app]).strip())
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

        send_msg_button = self.app.select_single(objectName='logMessageButton')
        self.pointing_device.click_object(send_msg_button)

        msg_app = self._get_app_proxy_object('messaging-app')
        msg_app_view = msg_app.select_single('QQuickView')
        msgs_pane = msg_app.select_single(objectName='messagesPage')
        
        self.assertThat(msg_app_view.visible, Eventually(Equals(True)))
        self.assertThat(msgs_pane.visible, Eventually(Equals(True)))

        self.addCleanup(os.system, 'pkill messaging-app')
