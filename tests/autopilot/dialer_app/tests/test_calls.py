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

import os
import time

from autopilot.matchers import Eventually
from testtools.matchers import Equals, NotEquals, MismatchError
from testtools import skipIf, skipUnless

from dialer_app.tests import DialerAppTestCase
from dialer_app import helpers
from dialer_app import fixture_setup


@skipUnless(helpers.is_phonesim_running(),
            "this test needs to run under with-ofono-phonesim")
@skipIf(os.uname()[2].endswith("maguro"),
        "tests cause Unity crashes on maguro")
class TestCalls(DialerAppTestCase):
    """Tests for simulated phone calls."""

    def setUp(self):
        empty_history = fixture_setup.UseEmptyHistory()
        self.useFixture(empty_history)
        phonesim_modem = fixture_setup.UsePhonesimModem()
        self.useFixture(phonesim_modem)
        super().setUp()

    def tearDown(self):
        super().tearDown()

    @property
    def history_list(self):
        # because of the object tree, more than just one item is returned, but
        # all references point to the same item, so take the first
        return self.app.select_many(objectName="historyList")[0]

    def get_history_for_number(self, number):
        # because of the bottom edge tree structure, multiple copies of the
        # same item are returned, so just use the first one
        return self.history_list.select_many(
            "HistoryDelegate", phoneNumber=number)[0]

    def test_outgoing_noanswer(self):
        """Outgoing call to a normal number, no answer"""
        number = "144"
        formattedNumber = "1 44"
        self.main_view.dialer_page.call_number(number, formattedNumber)
        self.assertThat(
            self.main_view.live_call_page.caller, Eventually(Equals(number)))

        # If we press the hangup button too quickly it won't end the call.
        # Reported as bug http://pad.lv/1351817
        time.sleep(1)
        self.main_view.live_call_page.click_hangup_button()

        # now the live call view stays open for a few seconds after the call
        # ends, so we need to wait for the dialpad view to be active before
        # trying to interact with the bottom edge
        self.main_view.dialer_page.active.wait_for(True)

        # log should show call to the phone number
        self.main_view.dialer_page.reveal_bottom_edge_page()
        self.assertThat(self.history_list.count, Eventually(Equals(1)))
        # because of the bottom edge tree structure, multiple copies of the
        # same item are returned, so just use the first one
        self.assertThat(self.get_history_for_number(number), NotEquals(None))

    def test_outgoing_answer_local_hangup(self):
        """Outgoing call, remote answers, local hangs up"""
        # 06123xx causes accept after xx seconds
        number = "0612302"
        formattedNumber = "061-2302"

        self.main_view.dialer_page.call_number(number, formattedNumber)
        self.assertThat(
            self.main_view.live_call_page.caller, Eventually(Equals(number)))

        # stop watch should start counting
        elapsed_time = self.main_view.live_call_page.get_elapsed_call_time()
        self.assertIn("00:0", elapsed_time)

        # should still be connected after some time
        time.sleep(3)
        self.assertIn("00:0", elapsed_time)
        self.main_view.live_call_page.click_hangup_button()

    def test_outgoing_answer_remote_hangup(self):
        """Outgoing call, remote answers and hangs up"""
        number = "0512303"
        formattedNumber = "051-2303"

        # 05123xx causes immediate accept and hangup after xx seconds
        self.main_view.dialer_page.call_number(number, formattedNumber)
        self.assertThat(
            self.main_view.live_call_page.caller, Eventually(Equals(number)))

        # stop watch should start counting
        elapsed_time = self.main_view.live_call_page.get_elapsed_call_time()
        self.assertIn("00:0", elapsed_time)

        # wait for the live call view to be gone
        self.main_view.dialer_page.active.wait_for(True)

        # after remote hangs up, should switch to call log page and show call
        # to number
        self.main_view.dialer_page.reveal_bottom_edge_page()
        self.assertThat(self.history_list.visible, Eventually(Equals(True)))
        self.assertThat(self.history_list.count, Eventually(Equals(1)))
        self.assertThat(self.get_history_for_number(number), NotEquals(None))

    def test_incoming(self):
        """Incoming call"""
        number = "1234567"
        helpers.invoke_incoming_call(number)

        # wait for incoming call, accept; it would be nicer to fake-click the
        # popup notification, but as this isn't generated by dialer-app it
        # isn't exposed to autopilot
        helpers.wait_for_incoming_call()
        time.sleep(1)  # let's hear the ringing sound for a second :-)
        helpers.accept_incoming_call()

        # call back is from that number
        self.assertThat(
            self.main_view.live_call_page.caller, Eventually(Equals(number)))

        # stop watch should start counting
        elapsed_time = self.main_view.live_call_page.get_elapsed_call_time()
        self.assertIn("00:0", elapsed_time)

        try:
            self.main_view.live_call_page.click_hangup_button()
        except MismatchError as e:
            print('Expected failure due to known Mir crash '
                  '(https://launchpad.net/bugs/1240400): %s' % e)

    def test_last_called_number(self):
        number = "1234567"
        formattedNumber = "1 234-567"

        number2 = "1231234567"
        formattedNumber2 = "1 231-234-567"

        self.main_view.dialer_page.call_number(number, formattedNumber)
        time.sleep(3)
        self.main_view.live_call_page.click_hangup_button()
        self.main_view.dialer_page.active.wait_for(True)

        self.main_view.dialer_page.call_number(number2, formattedNumber2)
        time.sleep(3)
        self.main_view.live_call_page.click_hangup_button()
        self.main_view.dialer_page.active.wait_for(True)

        self.main_view.dialer_page.reveal_bottom_edge_page()
        self.assertThat(self.history_list.visible, Eventually(Equals(True)))
        self.assertThat(self.history_list.count, Eventually(Equals(1)))
        historyEntry = self.get_history_for_number(number)
        self.main_view._click_button(historyEntry)
        self.assertThat(
            self.main_view.dialer_page.dialNumber,
            Eventually(Equals(formattedNumber2)))
