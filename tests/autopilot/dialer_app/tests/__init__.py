# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Dialer App autopilot tests."""

from autopilot.input import Mouse, Touch, Pointer
from autopilot.matchers import Eventually
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase
from testtools.matchers import Equals, GreaterThan

from dialer_app.emulators.call_panel import CallPanel

from dialer_app.emulators.utils import Utils

import os
from time import sleep
import logging

logger = logging.getLogger(__name__)


class DialerAppTestCase(AutopilotTestCase):
    """A common test case class that provides several useful methods for
    Dialer App tests.

    """

    if model() == 'Desktop':
        scenarios = [
        ('with mouse', dict(input_device_class=Mouse)),
        ]
    else:
        scenarios = [
        ('with touch', dict(input_device_class=Touch)),
        ]

    local_location = "../../src/dialer-app"

    def setUp(self):
        self.pointing_device = Pointer(self.input_device_class.create())
        super(DialerAppTestCase, self).setUp()

        if os.path.exists(self.local_location):
            self.launch_test_local()
        else:
            self.launch_test_installed()

        main_view = self.get_main_view()
        self.assertThat(main_view.visible, Eventually(Equals(True)))

    def launch_test_local(self):
        self.app = self.launch_test_application(
            self.local_location, "--test-contacts", app_type='qt')

    def launch_test_installed(self):
        if model() == 'Desktop':
            self.app = self.launch_test_application(
                "dialer-app",
                "--test-contacts")
        else:
            self.app = self.launch_test_application(
               "dialer-app", 
               "--test-contacts",
               "--desktop_file_hint=/usr/share/applications/dialer-app.desktop",
               app_type='qt')

    def get_main_view(self):
        return self.app.select_single("QQuickView")

    def get_tabs(self):
        """Returns the top tabs bar."""
        return self.app.select_single("NewTabBar")

    def click_item(self, item, delay=0.1):
        """Does a mouse click on the passed item, and moved the mouse there
           before"""
        # In jenkins test may fail because we don't wait before clicking the
        # target so we add a little delay before click.
        if model() == 'Desktop' and delay <= 0.25:
            delay = 0.25

        self.pointing_device.move_to_object(item)
        sleep(delay)
        self.pointing_device.click()

    def switch_to_conversation_tab(self):
        tabs_bar = self.get_tabs()
        conversation_pane = self.utils.get_conversations_pane()
        self.click_item(tabs_bar)

        conversations_tab_button = self.utils.get_conversations_tab_button()
        self.assertThat(conversations_tab_button.opacity,
                        Eventually(GreaterThan(0.35)))
        self.click_item(conversations_tab_button)

        self.assertThat(conversation_pane.isCurrent, Eventually(Equals(True)))

    def switch_to_contacts_tab(self):
        tabs_bar = self.get_tabs()
        contacts_pane = self.utils.get_contacts_pane()
        
        x, y, w, h = tabs_bar.globalRect
        tx = x + (w - w / 8)
        ty = y + h / 2
        self.pointing_device.drag(tx, ty, tx / 8, ty)

        contacts_tab_button = self.utils.get_contacts_tab_button()
        self.assertThat(contacts_tab_button.opacity,
                        Eventually(GreaterThan(0.35)))
        self.click_item(contacts_tab_button)

        self.assertThat(contacts_pane.isCurrent, Eventually(Equals(True)))

    def reveal_toolbar(self):
        main_view = self.get_main_view()
        x_line = main_view.x + main_view.width * 0.5
        start_y = main_view.y + main_view.height - 1
        stop_y = start_y - 200
        self.pointing_device.drag(x_line, start_y, x_line, stop_y)

    @property
    def call_panel(self):
        return CallPanel(self.app)

    @property
    def contacts_panel(self):
        return ContactsPanel(self.app)

    @property
    def utils(self):
        return Utils(self.app)
