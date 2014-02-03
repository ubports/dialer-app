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


class TestDialer(DialerAppTestCase):
    """Tests for the Call panel."""

    def setUp(self):
        super(TestDialer, self).setUp()

    def test_keypad_buttons(self):
        keypad_entry = self.main_view.dialer_page.get_keypad_entry()
        keypad_keys = self.main_view.dialer_page.get_keypad_keys()

        text = ""
        for key in keypad_keys:
            self.pointing_device.click_object(key)
            text += key.label

        self.assertThat(keypad_entry.value, Eventually(Equals(text)))

    def test_erase_button(self):
        keypad_entry = self.main_view.dialer_page.get_keypad_entry()
        buttonOne = self.main_view.dialer_page.get_keypad_key("1")
        buttonTwo = self.main_view.dialer_page.get_keypad_key("2")
        buttonThree = self.main_view.dialer_page.get_keypad_key("3")
        eraseButton = self.main_view.dialer_page.get_erase_button()

        self.pointing_device.click_object(buttonOne)
        self.pointing_device.click_object(buttonTwo)
        self.pointing_device.click_object(buttonThree)

        self.assertThat(keypad_entry.value, Eventually(Equals("123")))

        self.pointing_device.click_object(eraseButton)
        self.assertThat(keypad_entry.value, Eventually(Equals("12")))

        self.pointing_device.click_object(eraseButton)
        self.pointing_device.click_object(eraseButton)
        self.assertThat(keypad_entry.value, Eventually(Equals("")))

    def test_dialer_view_is_default(self):
        """Ensure the dialer view is the default view on app startup."""
        dialer_page = self.main_view.dialer_page

        self.assertThat(dialer_page.visible, Eventually(Equals(True)))
