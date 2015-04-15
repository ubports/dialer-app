# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2015 Canonical
# Author: Martin Pitt <martin.pitt@ubuntu.com>
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Multiple calls tests for the Dialer App using ofono-phonesim"""

import subprocess
import time

from autopilot.matchers import Eventually
from testtools.matchers import Equals, NotEquals, MismatchError
from testtools import skipUnless

from dialer_app.tests import DialerAppTestCase
from dialer_app import helpers
from dialer_app import fixture_setup


@skipUnless(helpers.is_phonesim_running(),
            "this test needs to run under with-ofono-phonesim")
class TestMultiCalls(DialerAppTestCase):
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

    def place_calls(self, numbers):
        for number in numbers:
            helpers.invoke_incoming_call(number)
            helpers.wait_for_incoming_call()
            time.sleep(1)
            helpers.accept_incoming_call()
            time.sleep(1)

    def test_multi_call_panel(self):
        """Make sure the multi call panel is visible when two calls are
           available"""
        firstNumber = '11111111'
        secondNumber = '22222222'

        # place the calls
        self.place_calls([firstNumber, secondNumber])

        # now ensure that the multi-call panel is visible
        multi_call = self.main_view.live_call_page.get_multi_call_display()
        self.assertThat(multi_call.visible, Eventually(Equals(True)))

        # hangup one call
        self.main_view.live_call_page.click_hangup_button()
        self.assertThat(multi_call.visible, Eventually(Equals(False)))

        # and the other one
        self.main_view.live_call_page.click_hangup_button()

    def test_swap_calls(self):
        """Check that pressing the swap calls button change the call status"""
        firstNumber = '11111111'
        secondNumber = '22222222'

        # place the calls
        self.place_calls([firstNumber, secondNumber])

        live_call = self.main_view.live_call_page
        firstCallItem = live_call.get_multi_call_item_for_number(firstNumber)
        secondCallItem = live_call.get_multi_call_item_for_number(secondNumber)

        # check the current status
        self.assertThat(firstCallItem.active, Eventually(Equals(False)))
        self.assertThat(secondCallItem.active, Eventually(Equals(True)))

        # now swap the calls
        live_call.click_swap_calls_button()

        # and make sure the calls changed
        self.assertThat(firstCallItem.active, Eventually(Equals(True)))
        self.assertThat(secondCallItem.active, Eventually(Equals(False)))

        # hangup the calls
        self.main_view.live_call_page.click_hangup_button()
        time.sleep(1)
        self.main_view.live_call_page.click_hangup_button()

    def test_swap_and_hangup(self):
        """Check that after swapping calls and hanging up the correct call
           stays active"""
        firstNumber = '11111111'
        secondNumber = '22222222'

        # place the calls
        self.place_calls([firstNumber, secondNumber])

        # at this point the calls should be like this:
        #  - 11111111: held
        #  - 22222222: active
        # swap the calls then
        self.main_view.live_call_page.click_swap_calls_button()

        # - 11111111: active
        # - 22222222: held
        self.assertThat(
            self.main_view.live_call_page.caller,
            Eventually(Equals(firstNumber)))

        # hangup the active call
        self.main_view.live_call_page.click_hangup_button()

        # and check that the remaining call is the one that was held
        self.assertThat(
            self.main_view.live_call_page.caller,
            Eventually(Equals(secondNumber)))

        # and hangup the remaining call too
        self.main_view.live_call_page.click_hangup_button()
