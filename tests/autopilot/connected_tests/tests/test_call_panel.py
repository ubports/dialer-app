# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Dialer App"""

from __future__ import absolute_import

from autopilot.matchers import Eventually
from testtools.matchers import Equals, NotEquals

from connected_tests.tests import DialerAppTestCase

import unittest
import time


class TestCallPanel(DialerAppTestCase):
    """Tests for the Call panel."""

    def setUp(self):
        super(TestCallPanel, self).setUp()
        dialer_page = self.call_panel.get_dialer_page()
        self.assertThat(dialer_page.isCurrent, Eventually(Equals(True)))

    def test_calling_is_intact(self):
        keypad_entry = self.call_panel.get_keypad_entry()
        keypad_keys = self.call_panel.get_keypad_keys()
        dial_end_button = self.call_panel.get_dial_button()
        call_time = self.call_panel.get_call_stopwatch()

        self.dial_number(self.PHONE_NUMBER)        
        self.assertThat(keypad_entry.value, Eventually(Equals(self.PHONE_NUMBER)))

        self.pointing_device.click_object(dial_end_button)
        on_call_panel = self.call_panel.get_on_call_panel()
        self.assertThat(on_call_panel.enabled, Eventually(Equals(True)))

        wait = self.CALL_WAIT
        while call_time.time == 0 and wait != 0:
            time.sleep(1)
            wait = wait - 1
            if wait == 0 and call_time.time == 0:
                self.pointing_device.click_object(dial_end_button)
                self.assertThat(call_time.time, Eventually(Equals(0)))
                self.skipTest("Call was not picked on the other end")

        time.sleep(self.CALL_DURATION)
        self.pointing_device.click_object(dial_end_button)
        self.assertThat(call_time.time, Eventually(Equals(0)))
        communication_view = self.communication_panel.get_communication_view()
        self.assertThat(communication_view.visible, Eventually(Equals(True)))
