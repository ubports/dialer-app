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

import os
import subprocess

from autopilot.platform import model
from autopilot.matchers import Eventually
from testtools import skipIf
from testtools.matchers import Equals
from url_dispatcher_testability import (
    fake_dispatcher,
    fixture_setup as url_dispatcher_fixtures
)

from dialer_app.tests import DialerAppTestCase
from dialer_app import fixture_setup
from dialer_app import ListItemWithActions


@skipIf(model() == 'Desktop',
        'only run on Ubuntu touch platforms')
class TestCallLogs(DialerAppTestCase):
    """Tests for the call log panel."""

    db_file = 'history.sqlite'
    local_db_dir = 'dialer_app/data/'
    system_db_dir = '/usr/lib/python3/dist-packages/dialer_app/data/'

    def setUp(self):
        if os.path.exists('../../src/dialer-app'):
            database = self.local_db_dir + self.db_file
        else:
            database = self.system_db_dir + self.db_file

        subprocess.call(['pkill', 'history-daemon'])
        os.environ['HISTORY_SQLITE_DBPATH'] = database
        with open(os.devnull, 'w') as devnull:
            subprocess.Popen(['history-daemon'], stderr=devnull)

        super().setUp()
        testability_environment = fixture_setup.TestabilityEnvironment()
        self.useFixture(testability_environment)
        self.main_view.dialer_page.reveal_bottom_edge_page()
        self.addCleanup(subprocess.call, ['pkill', '-f', 'history-daemon'])
        self.fake_url_dispatcher = url_dispatcher_fixtures.FakeURLDispatcher()
        self.useFixture(self.fake_url_dispatcher)

    def _get_main_view(self, proxy_object):
        return proxy_object.wait_select_single('QQuickView')

    def get_last_dispatch_url_call_parameter(self):
        try:
            fake = self.fake_url_dispatcher
            return fake.get_last_dispatch_url_call_parameter()
        except fake_dispatcher.FakeDispatcherException:
            return None

    def test_call_log_item_opens_messaging(self):
        """Ensure tapping on 'send text message' item of a call log opens
        the messaging app.

        """
        delegate = self.main_view.wait_select_single(
            ListItemWithActions.HistoryDelegate, objectName='historyDelegate0')
        delegate.active_action(3)

        self.assertThat(
            self.get_last_dispatch_url_call_parameter,
            Eventually(Equals('message:///800')))

    def test_add_new_contact_from_log(self):
        """Ensure tapping on 'add new contact' item of a call log opens
        the address-book app to allow adding new contact.

        """
        delegate = self.main_view.wait_select_single(
            ListItemWithActions.HistoryDelegate, objectName='historyDelegate0')
        delegate.active_action(2)

        self.assertThat(
            self.get_last_dispatch_url_call_parameter,
            Eventually(Equals(
                'addressbook:///addnewphone?callback=dialer-app.desktop&'
                'phone=800')))
