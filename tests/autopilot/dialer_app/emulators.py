# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Dialer app autopilot emulators."""

from ubuntuuitoolkit import emulators as toolkit_emulators


class MainView(toolkit_emulators.MainView):
    def __init__(self, *args):
        super(MainView, self).__init__(*args)

    @property
    def dialer_page(self):
        return self.wait_select_single(DialerPage)

    @property
    def live_call_page(self):
        return self.wait_select_single(LiveCall)

    def get_first_log(self):
        return self.wait_select_single(objectName="historyDelegate0")

    def _click_button(self, button):
        """Generic way to click a button"""
        button.visible.wait_for(True)
        self.pointing_device.click_object(button)
        return button


class LiveCall(MainView):
    def __init__(self, *args):
        super(LiveCall, self).__init__(*args)

    def stop_watch(self):
        return self.wait_select_single(objectName="stopWatch")

    def _get_hangup_button(self):
        """Returns the hangup button"""
        return self.wait_select_single(objectName='hangupButton')

    def click_hangup_button(self):
        """Clicks and returns the hangup page"""
        self.visible.wait_for(True)
        return self._click_button(self._get_hangup_button())


class DialerPage(MainView):
    def __init__(self, *args):
        super(DialerPage, self).__init__(*args)

    def _get_keypad_entry(self):
        return self.select_single("KeypadEntry")

    def _get_keypad_keys(self):
        return self.select_many("KeypadButton")

    def _get_keypad_key(self, number):
        buttons_dict = {
            "0": "buttonZero",
            "1": "buttonOne",
            "2": "buttonTwo",
            "3": "buttonThree",
            "4": "buttonFour",
            "5": "buttonFive",
            "6": "buttonSix",
            "7": "buttonSeven",
            "8": "buttonEight",
            "9": "buttonNine",
            "*": "buttonAsterisk",
            "#": "buttonHash",
        }
        return self.select_single("KeypadButton",
                                  objectName=buttons_dict[number])

    def _get_erase_button(self):
        """Returns the erase button"""
        return self.select_single("CustomButton", objectName="eraseButton")

    def _get_call_button(self):
        """Returns the call button"""
        return self.select_single(objectName="callButton")

    def click_call_button(self):
        """Clicks and returns the call button"""
        return self._click_button(self._get_call_button())

    def click_erase_button(self):
        """Clicks and returns the erase button"""
        return self._click_button(self._get_erase_button())

    def click_keypad_button(self, keypad_button):
        """clicks the keypad button

        :param returns: the clicked keypad_button
        """
        return self._click_button(keypad_button)

    def dial_number(self, number):
        """Dial given number (string) on the keypad and call

        :param number: the number to dial
        """
        for digit in number:
            button = self._get_keypad_key(digit)
            self.click_keypad_button(button)

        entry = self._get_keypad_entry()
        entry.value.wait_for(number)
        return entry

    def call_number(self, number):
        self.dial_number(number)
        return self.click_call_button()
