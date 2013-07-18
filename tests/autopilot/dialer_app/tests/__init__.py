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

