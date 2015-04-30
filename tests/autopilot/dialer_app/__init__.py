# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014 Canonical
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Dialer app autopilot custom proxy objects."""

import logging

import ubuntuuitoolkit
from autopilot import exceptions as autopilot_exceptions


class MainView(ubuntuuitoolkit.MainView):
    def __init__(self, *args):
        super().__init__(*args)
        self.logger = logging.getLogger(__name__)

    @property
    def dialer_page(self):
        return self.wait_select_single(DialerPage, greeterMode=False)

    @property
    def live_call_page(self):
        # wait until we actually have the calls before returning the live call
        self.hasCalls.wait_for(True)
        return self.wait_select_single(LiveCall, active=True)

    def get_first_log(self):
        return self.wait_select_single(objectName="historyDelegate0")

    def _click_button(self, button):
        """Generic way to click a button"""
        self.visible.wait_for(True)
        button.visible.wait_for(True)
        self.pointing_device.click_object(button)
        return button

    def check_ussd_error_dialog_visible(self):
        """Check if ussd error dialog is visible"""
        dialog = None
        try:
            dialog = self.wait_select_single(objectName="ussdErrorDialog")
        except:
            # it is ok to fail in this case
            return False
        
        return dialog.visible

    def check_ussd_progress_indicator_visible(self):
        """Check if ussd progress indicator is visible"""
        dialog = None
        try:
            dialog = self.wait_select_single(objectName="ussdProgressIndicator")
        except:
            # it is ok to fail in this case
            return False

        return dialog.visible


class LiveCall(MainView):

    def get_elapsed_call_time(self):
        """Return the elapsed call time"""
        return self.wait_select_single(objectName='stopWatch').elapsed

    def _get_hangup_button(self):
        """Return the hangup button"""
        return self.wait_select_single(objectName='hangupButton')

    def _get_call_hold_button(self):
        """Return the call holding button"""
        return self.wait_select_single(objectName='callHoldButton')

    def _get_swap_calls_button(self):
        """Return the swap calls button"""
        return self._get_call_hold_button()

    def get_multi_call_display(self):
        """Return the multi call display panel"""
        return self.wait_select_single(objectName='multiCallDisplay')

    def get_multi_call_item_for_number(self, number):
        """Return the multi call display item for the given number"""
        return self.wait_select_single(objectName='callDelegate',
                                       phoneNumber=number)

    def click_hangup_button(self):
        """Click and return the hangup page"""
        return self._click_button(self._get_hangup_button())

    def click_call_hold_button(self):
        """Click the call holding button"""
        return self._click_button(self._get_call_hold_button())

    def click_swap_calls_button(self):
        """Click the swap calls button"""
        return self._click_button(self._get_swap_calls_button())


class PageWithBottomEdge(MainView):

    """Autopilot custom proxy object for PageWithBottomEdge components."""

    def reveal_bottom_edge_page(self):
        """Bring the bottom edge page to the screen"""
        self.bottomEdgePageLoaded.wait_for(True)
        try:
            action_item = self.wait_select_single(objectName='bottomEdgeTip')
            start_x = (
                action_item.globalRect.x +
                (action_item.globalRect.width * 0.5))
            # Start swiping from the top of the component because after some
            # seconds it gets almost fully hidden. The center will be out of
            # view.
            start_y = action_item.globalRect.y + (action_item.height * 0.2)
            stop_y = start_y - (self.height * 0.7)
            self.pointing_device.drag(start_x, start_y, start_x, stop_y,
                                      rate=2)
            self.isReady.wait_for(True)
        except autopilot_exceptions.StateNotFoundError:
            self.logger.error('BottomEdge element not found.')
            raise


class DialerPage(PageWithBottomEdge):

    def _get_keypad_entry(self):
        return self.wait_select_single("KeypadEntry")

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
        return self.wait_select_single("KeypadButton",
                                       objectName=buttons_dict[number])

    def _get_erase_button(self):
        """Return the erase button"""
        return self.wait_select_single("CustomButton",
                                       objectName="eraseButton")

    def _get_call_button(self):
        """Return the call button"""
        return self.wait_select_single(objectName="callButton")

    def click_call_button(self):
        """Click and return the call button"""
        return self._click_button(self._get_call_button())

    def click_erase_button(self):
        """Click the erase button"""
        self._click_button(self._get_erase_button())

    def click_keypad_button(self, keypad_button):
        """click the keypad button

        :param keypad_button: the clicked keypad_button
        """
        self._click_button(keypad_button)

    def dial_number(self, number, formattedNumber):
        """Dial given number (string) on the keypad and return keypad entry

        :param number: the number to dial
        """
        for digit in number:
            button = self._get_keypad_key(digit)
            self.click_keypad_button(button)

        entry = self._get_keypad_entry()
        entry.value.wait_for(formattedNumber)
        return entry

    def call_number(self, number, formattedNumber):
        """Dial number and call return call_button"""
        self.dial_number(number, formattedNumber)
        self.click_call_button()
        return self.get_root_instance().wait_select_single(LiveCall)
