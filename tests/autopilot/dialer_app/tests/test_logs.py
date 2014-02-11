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
from autopilot.platform import model
from testtools.matchers import Equals
from testtools import skipIf

from dialer_app.tests import DialerAppTestCase
from dialer_app import fixture_setup

import os
import subprocess
import time
import unittest


@skipIf(model() == 'Desktop',
        'only run on Ubuntu touch platforms')
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
        testability_environment = fixture_setup.TestabilityEnvironment()
        self.useFixture(testability_environment)
        self.main_view.switch_to_tab('callLogTab')
        self._ensure_call_log_item_expanded()
        self.addCleanup(subprocess.call, ['pkill', '-f', 'history-daemon'])

    def _ensure_call_log_item_expanded(self):
        history_item = self.main_view.get_first_log()
        self.pointing_device.click_object(history_item)

        history_item.detailsShown.wait_for(True)
        history_item.animating.wait_for(False)

    def _get_main_view(self, proxy_object):
        return proxy_object.select_single('QQuickView')

    def test_call_log_item_opens_messaging(self):
        """Ensure tapping on 'send text message' item of a call log opens
        the messaging app.

        """
        self._click_object('logMessageButton')

        msg_app = self._get_app_proxy_object('messaging-app')
        msg_app_view = self._get_main_view(msg_app)
        msgs_pane = msg_app.select_single(objectName='messagesPage')

        self.assertThat(msg_app_view.visible, Eventually(Equals(True)))
        self.assertThat(msgs_pane.visible, Eventually(Equals(True)))
        self.assertThat(msgs_pane.number, Eventually(Equals("800")))

        self.addCleanup(subprocess.call, ['pkill', '-f', 'messaging-app'])

    @unittest.skip('Test is failing, due to OSD bug, will re-enable soon')
    def test_add_new_contact_from_log(self):
        """Ensure tapping on 'add new contact' item of a call log opens
        the address-book app to allow adding new contact.

        """
        self._click_object('logAddContactButton')

        save_contact_dialog = self.app.select_single(
            objectName='saveContactDialog'
        )
        self.assertThat(save_contact_dialog.opacity, Eventually(Equals(1)))

        self._click_object('addNewContactButton')

        cntct_app = self._get_app_proxy_object('address-book-app')
        cntct_app_view = self._get_main_view(cntct_app)
        cntct_edit_pane = cntct_app.select_single(
            objectName='contactEditorPage')
        numbr_box = cntct_app.select_single(objectName="phoneNumber_0")

        self.assertThat(cntct_app_view.visible, Eventually(Equals(True)))
        self.assertThat(cntct_edit_pane.visible, Eventually(Equals(True)))
        self.assertThat(numbr_box.text, Eventually(Equals("800")))

        self.addCleanup(subprocess.call, ['pkill', '-f', 'address-book-app'])
