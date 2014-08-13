# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012, 2013, 2014 Canonical
#
# This file is part of dialer-app.
#
# dialer-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Dialer App autopilot tests."""

import logging
import os
import subprocess
import time

import fixtures
import ubuntuuitoolkit
from autopilot.input import Mouse, Touch, Pointer
from autopilot.introspection import get_proxy_object_for_existing_process
from autopilot.matchers import Eventually
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase
from testtools.matchers import Equals
from ubuntuuitoolkit import fixture_setup

import dialer_app
from dialer_app import helpers

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

    LOCAL_BINARY_PATH = 'src/dialer-app'
    # The path to the locally built binary, relative to the build directory.

    def setUp(self):
        self.pointing_device = Pointer(self.input_device_class.create())
        super().setUp()

        self.set_up_locale()

        self.launch_application()

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

    def launch_application(self):
        build_dir = os.environ.get('BUILD_DIR', None)
        if build_dir is not None:
            self.launch_built_application(build_dir)
        else:
            self.launch_installed_application()

    def launch_built_application(self, build_dir):
        binary_path = os.path.join(build_dir, self.LOCAL_BINARY_PATH)
        self.app = self.launch_test_application(
            binary_path,
            app_type='qt',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase
        )

    def launch_installed_application(self):
        self.app = self.launch_upstart_application(
            'dialer-app',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase
        )

    def _get_app_proxy_object(self, app_name):
        return get_proxy_object_for_existing_process(
            pid=self._get_app_pid(app_name),
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase
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
            self.app.wait_select_single(objectName=objectName)
        )

    @property
    def main_view(self):
        return self.app.wait_select_single(dialer_app.MainView)
