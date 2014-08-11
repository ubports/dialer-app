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

from autopilot.platform import model
from testtools import skipIf
from url_dispatcher_testability import fixture_setup as url_dispatcher_fixtures

from dialer_app.tests import DialerAppTestCase
from dialer_app import fixture_setup
from dialer_app import ListItemWithActions

import os
import subprocess


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

    def _get_main_view(self, proxy_object):
        return proxy_object.wait_select_single('QQuickView')

    def test_call_log_item_opens_messaging(self):
        """Ensure tapping on 'send text message' item of a call log opens
        the messaging app.

        """
        fake_url_dispatcher = url_dispatcher_fixtures.FakeURLDispatcher()
        self.useFixture(fake_url_dispatcher)

        delegate = self.main_view.wait_select_single(
            ListItemWithActions.HistoryDelegate, objectName='historyDelegate0')
        delegate.active_action(2)

        self.assertEqual(
            fake_url_dispatcher.get_last_dispatch_url_call_parameter(),
            'message:///800')

    def test_add_new_contact_from_log(self):
        """Ensure tapping on 'add new contact' item of a call log opens
        the address-book app to allow adding new contact.

        """
        fake_url_dispatcher = url_dispatcher_fixtures.FakeURLDispatcher()
        self.useFixture(fake_url_dispatcher)

        delegate = self.main_view.wait_select_single(
            ListItemWithActions.HistoryDelegate, objectName='historyDelegate0')
        delegate.active_action(1)

        self.assertEqual(
            fake_url_dispatcher.get_last_dispatch_url_call_parameter(),
            'addressbook:///addnewphone?phone=800')
