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
from testtools.matchers import Equals

from dialer_app.tests import DialerAppTestCase


class TestCallPanel(DialerAppTestCase):
    """Tests for the Call panel."""

    def setUp(self):
        super(TestCallPanel, self).setUp()
        dialer_page = self.call_panel.get_dialer_page()
        self.assertThat(dialer_page.isCurrent, Eventually(Equals(True)))

    def test_keypad(self):
        """The Keypad works, either using a hardware keyboard or the in-app buttons"""
        keypad_entry = self.call_panel.get_keypad_entry()
        keypad_keys = self.call_panel.get_keypad_keys()

        for keys in keypad_keys:
            self.pointing_device.move_to_object(keys)
            self.pointing_device.click()
        
        self.assertThat(keypad_entry.value, Eventually(Equals("123456789*0#")))

    def test_switch_to_contacts(self):
        """Switching to the contact list using the dialers contacts button"""
        dialer_page = self.call_panel.get_dialer_page()
        contacts_page = self.call_panel.get_contacts_page()

        self.assertThat(dialer_page.isCurrent, Eventually(Equals(True)))
        self.assertThat(contacts_page.isCurrent, Eventually(Equals(False)))
        
        contacts_list_button = self.call_panel.get_contacts_list_button()
        self.pointing_device.move_to_object(contacts_list_button)
        self.pointing_device.click()
        
        self.assertThat(dialer_page.isCurrent, Eventually(Equals(False)))
        self.assertThat(contacts_page.isCurrent, Eventually(Equals(True)))
