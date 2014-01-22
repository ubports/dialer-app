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
from testtools.matchers import Equals

from dialer_app.tests import DialerAppTestCase

import os
import subprocess


class TestContacts(DialerAppTestCase):
    """Tests for the contacts panel."""

    def setUp(self):
        # provide clean history
        self.history = os.path.expanduser(
            "~/.local/share/history-service/history.sqlite")
        if os.path.exists(self.history):
            subprocess.call(["pkill", "history-daemon"])
            os.rename(self.history, self.history + ".orig")

        os.environ["HISTORY_SQLITE_DBPATH"] = "../data/history.sqlite"
        subprocess.Popen(["history-daemon"])

        super(TestContacts, self).setUp()

    def tearDown(self):
        super(TestContacts, self).tearDown()

        # restore history
        if os.path.exists(self.history + ".orig"):
            subprocess.call(["pkill", "history-daemon"])
            os.rename(self.history + ".orig", self.history)

    def test_call_log_item_integration(self):
        """Ensure tapping on different items of a call log opens
        the right application.

        """
        self.main_view.switch_to_tab("callLogTab")
        history_item = self.app.select_single(objectName="historyDelegate0")
        self.pointing_device.click_object(history_item)
        self.assertThat(history_item.detailsShown, Eventually(Equals(True)))
