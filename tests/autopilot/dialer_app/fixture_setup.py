# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2014 Canonical Ltd.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

"""Set up and clean up fixtures for the Inter-app integration tests."""


import fixtures
import subprocess


class TestabilityEnvironment(fixtures.Fixture):

    def setUp(self):
        super(TestabilityEnvironment, self).setUp()
        self._set_testability_environment_variable()
        self.addCleanup(self._reset_environment_variable)

    def _set_testability_environment_variable(self):
        """Make sure every app loads the testability driver."""
        subprocess.call(
            [
                '/sbin/initctl',
                'set-env',
                '--global',
                'QT_LOAD_TESTABILITY=1'
            ]
        )

    def _reset_environment_variable(self):
        """Resets the previously added env variable."""
        subprocess.call(
            [
                '/sbin/initctl',
                'unset-env',
                'QT_LOAD_TESTABILITY'
            ]
        )
