# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
# Author: Martin Pitt <martin.pitt@ubuntu.com>
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Dialer App using ofono-phonesim"""

from __future__ import absolute_import

import subprocess
import os

from autopilot.matchers import Eventually
from testtools.matchers import Equals, NotEquals
from testtools import skipUnless

from dialer_app.tests import DialerAppTestCase

# determine whether we are running with phonesim
try:
    out = subprocess.check_output(["/usr/share/ofono/scripts/list-modems"],
                                  stderr=subprocess.PIPE)
    have_phonesim = out.startswith("[ /phonesim ]")
except CalledProcessError:
    have_phonesim = False

@skipUnless(have_phonesim,
            "this test needs to run under with-ofono-phonesim")
class TestCalls(DialerAppTestCase):
    """Tests for simulated phone calls."""

    def setUp(self):
        # provide clean history
        self.history = os.path.expanduser('~/.local/share/history-service/history.sqlite')
        if os.path.exists(self.history):
            subprocess.call(['pkill', 'history-daemon'])
            os.rename(self.history, self.history + '.orig')

        super(TestCalls, self).setUp()
        self.entry = self.main_view.dialer_page.get_keypad_entry()
        self.call_button = self.main_view.dialer_page.get_call_button()

        # should have an empty history at the beginning of each test
        self.history_list = self.app.select_single(objectName="historyList")
        self.assertThat(self.history_list.visible, Equals(False))
        self.assertThat(self.history_list.count, Equals(0))

        self.keys = []
        for i in range(10):
            self.keys.append(self.main_view.dialer_page.get_keypad_key(str(i)))

    def tearDown(self):
        super(TestCalls, self).tearDown()

        # ensure that there are no leftover calls in case of failed tests
        subprocess.call(['/usr/share/ofono/scripts/hangup-all'])

        # restore history
        if os.path.exists(self.history + '.orig'):
            subprocess.call(['pkill', 'history-daemon'])
            os.rename(self.history + '.orig', self.history)

    def test_outgoing_noanswer(self):
        """Outgoing call to a normal number, no answer"""

        # dial 144
        self.pointing_device.click_object(self.keys[1])
        self.pointing_device.click_object(self.keys[4])
        self.pointing_device.click_object(self.keys[4])
        self.assertThat(self.entry.value, Eventually(Equals("144")))

        self.pointing_device.click_object(self.call_button)

        # should switch to LiveCallPage, and show hangup button
        self.assertThat(lambda: self.app.select_single(objectName="hangupButton"), Eventually(NotEquals(None)))
        hangup_button = self.app.select_single(objectName="hangupButton")
        self.assertThat(hangup_button.visible, Eventually(Equals(True)))
        self.assertThat(self.call_button.visible, Equals(False))

        # hang up again
        self.pointing_device.click_object(hangup_button)
        self.assertThat(lambda: self.app.select_single(objectName="hangupButton"), Eventually(Equals(None)))

        # should switch to call log page
        self.assertThat(self.history_list.visible, Eventually(Equals(True)))
        self.assertThat(self.history_list.count, Equals(1))
