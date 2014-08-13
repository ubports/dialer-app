# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012, 2013 Canonical
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Dialer App autopilot tests."""

import fixtures
from autopilot.input import Mouse, Touch, Pointer
from autopilot.matchers import Eventually
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase
from testtools.matchers import Equals
from ubuntuuitoolkit import (
    emulators as toolkit_emulators,
    fixture_setup
)
from dialer_app import emulators
from dialer_app import helpers

import os
import logging

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
        super().setUp()

        self.set_up_locale()

        if os.path.exists(self.local_location):
            self.launch_test_local()
        else:
            self.launch_test_installed()

        self.assertThat(self.main_view.visible, Eventually(Equals(True)))

    def set_up_locale(self):
        # We set up the language to english to check the formatting of the
        # dialed number.
        self.useFixture(
            fixtures.EnvironmentVariable('LANGUAGE', newvalue='en')
        )
        self.useFixture(
            fixture_setup.InitctlEnvironmentVariable(LANGUAGE='en')
        )

    def launch_test_local(self):
        self.app = self.launch_test_application(
            self.local_location,
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase
        )

    def launch_test_installed(self):
        self.app = self.launch_upstart_application(
            'dialer-app',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase
        )

    def _click_object(self, objectName):
        self.pointing_device.click_object(
            self.app.wait_select_single(objectName=objectName)
        )

    @property
    def main_view(self):
        return self.app.wait_select_single(emulators.MainView)
