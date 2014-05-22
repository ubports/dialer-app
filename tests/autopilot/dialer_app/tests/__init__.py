# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012, 2013 Canonical
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Dialer App autopilot tests."""

from autopilot.input import Mouse, Touch, Pointer
from autopilot.introspection import get_proxy_object_for_existing_process
from autopilot.matchers import Eventually
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase
from testtools.matchers import Equals
from ubuntuuitoolkit import emulators as toolkit_emulators
from dialer_app import emulators
from dialer_app import helpers

import os
import time
import logging
import subprocess

logger = logging.getLogger(__name__)


# ensure we have an ofono account; we assume that we have these tools,
# otherwise we consider this a test failure (missing dependencies)
helpers.ensure_ofono_account()


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

        self.assertThat(self.main_view.visible, Eventually(Equals(True)))

    def launch_test_local(self):
        self.app = self.launch_test_application(
            self.local_location,
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def launch_test_installed(self):
        if model() == 'Desktop':
            self.app = self.launch_test_application(
                "dialer-app",
                emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)
        else:
            self.app = self.launch_test_application(
                "dialer-app",
                "--desktop_file_hint="
                "/usr/share/applications/dialer-app.desktop",
                app_type='qt',
                emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def _get_app_proxy_object(self, app_name):
        return get_proxy_object_for_existing_process(
            self._get_app_pid(app_name),
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase
        )

    def _get_app_pid(self, app):
        for i in range(10):
            try:
                return int(subprocess.check_output(['pidof', app]).strip())
            except subprocess.CalledProcessError:
                # application not started yet, check in a second
                time.sleep(1)

    def _click_object(self, objectName):
        self.pointing_device.click_object(
            self.app.select_single(objectName=objectName)
        )

    @property
    def main_view(self):
        return self.app.select_single(emulators.MainView)
