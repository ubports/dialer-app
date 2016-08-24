# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2015 Canonical
# Author: Tiago Salem Herrmann <tiago.herrmann@canonical.com>
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Dialer App using ofono-phonesim"""

import os

from autopilot.matchers import Eventually
from testtools.matchers import Equals
from testtools import skipIf, skipUnless

from dialer_app.tests import DialerAppTestCase
from dialer_app import helpers
from dialer_app import fixture_setup


@skipUnless(helpers.is_phonesim_running(),
            "this test needs to run under with-ofono-phonesim")
@skipIf(os.uname()[2].endswith("maguro"),
        "tests cause Unity crashes on maguro")
class TestUSSD(DialerAppTestCase):
    """Tests for simulated ussd sessions."""

    def setUp(self):
        phonesim_modem = fixture_setup.UsePhonesimModem()
        self.useFixture(phonesim_modem)
        notification_mock = fixture_setup.MockNotificationSystem()
        self.useFixture(notification_mock)
        super().setUp()

    def tearDown(self):
        super().tearDown()

    def test_ussd_invalid_code(self):
        """Test if invalid codes are properly notified"""
        number = "*123#"
        formattedNumber = "*123#"
        self.main_view.dialer_page.dial_number(number, formattedNumber)
        self.main_view.dialer_page.click_call_button()
        self.assertThat(self.main_view.check_ussd_error_dialog_visible(),
                        Eventually(Equals(True)))

    def test_ussd_valid_code(self):
        """Test if invalid codes are properly notified"""
        number = "*225#"
        formattedNumber = "*225#"
        self.main_view.dialer_page.dial_number(number, formattedNumber)
        self.main_view.dialer_page.click_call_button()

        self.assertThat(self.main_view.check_ussd_error_dialog_visible(),
                        Equals(False))
        self.assertThat(self.main_view.check_ussd_progress_dialog_visible(),
                        Equals(False))
