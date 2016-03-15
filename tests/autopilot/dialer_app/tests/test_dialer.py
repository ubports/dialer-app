# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Dialer App"""

from autopilot.matchers import Eventually
from testtools.matchers import Equals

from dialer_app.tests import DialerAppTestCase


class TestDialer(DialerAppTestCase):
    """Tests for the Call panel."""

    # FIXME: test disabled until we get a better way to test the keypad keys
    # def test_keypad_buttons(self):
    #    keypad_entry = self.main_view.dialer_page._get_keypad_entry()
    #    keypad_keys = self.main_view.dialer_page._get_keypad_keys()
    #
    #    text = ""
    #    for key in keypad_keys:
    #        self.main_view.dialer_page.click_keypad_button(key)
    #        text += key.label
    #
    #    self.assertThat(keypad_entry.value, Eventually(Equals(text)))

    def test_erase_button(self):
        keypad_entry = self.main_view.dialer_page.dial_number("123", "1 23")
        self.main_view.dialer_page.click_erase_button()

        self.assertThat(
            keypad_entry.value,
            Eventually(Equals("12"))
        )

        self.main_view.dialer_page.click_erase_button()
        self.main_view.dialer_page.click_erase_button()

        self.assertThat(
            keypad_entry.value,
            Eventually(Equals(""))
        )

    def test_dialer_view_is_default(self):
        """Ensure the dialer view is the default view on app startup."""
        dialer_page = self.main_view.dialer_page

        self.assertThat(dialer_page.visible, Eventually(Equals(True)))

    def test_dialer_copy_and_paste(self):
        keypad_entry = self.main_view.dialer_page._get_keypad_entry()
        keypad_keys = self.main_view.dialer_page._get_keypad_keys()
        tmpKey = None
        for key in keypad_keys:
            self.main_view.dialer_page.click_keypad_button(key)
            # to be used later
            tmpKey = key

        value = keypad_entry.value
        self.main_view.dialer_page.trigger_copy_and_paste()
        self.main_view.dialer_page.trigger_select_all()
        self.main_view.dialer_page.trigger_cut()

        self.assertThat(
            keypad_entry.value,
            Eventually(Equals(""))
        )

        # trigger paste
        self.main_view.dialer_page.trigger_copy_and_paste()
        self.main_view.dialer_page.trigger_paste()

        self.assertThat(
            keypad_entry.value,
            Eventually(Equals(value))
        )

        # select all text
        self.main_view.dialer_page.trigger_copy_and_paste()

        # first tap ouside just closes the copy and paste dialog
        self.main_view.dialer_page.click_keypad_button(tmpKey)

        # now change the text
        self.main_view.dialer_page.click_keypad_button(tmpKey)

        # check if selection is gone
        self.assertThat(keypad_entry.selectedText,
            Eventually(Equals(""))
        )
