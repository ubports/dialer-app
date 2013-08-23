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
        return self.select_single(DialerPage)


class DialerPage(toolkit_emulators.UbuntuUIToolkitEmulatorBase):
    def __init__(self, *args):
        super(DialerPage, self).__init__(*args)

    def get_keypad_entry(self):
        return self.select_single("KeypadEntry")

    def get_keypad_keys(self):
        return self.select_many("KeypadButton")

    def get_keypad_key(self, number):
        buttonsDict = {
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
        return self.select_single("KeypadButton", objectName=buttonsDict[number])

    def get_erase_button(self):
        return self.select_single("CustomButton", objectName="eraseButton")
