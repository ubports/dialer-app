find_program(QMLTESTRUNNER_BIN
    NAMES qmltestrunner
    PATHS /usr/lib/*/qt5/bin
    NO_DEFAULT_PATH
)

find_program(XVFB_RUN_BIN
    NAMES xvfb-run
)

macro(DECLARE_QML_TEST TST_NAME TST_QML_FILE)
    add_test(NAME ${TST_NAME}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMAND dbus-test-runner --task=${QMLTESTRUNNER_BIN} --parameter=-platform --parameter=offscreen --parameter=-import --parameter=${qml_BINARY_DIR} --parameter=-input --parameter=${CMAKE_CURRENT_SOURCE_DIR}/${TST_QML_FILE}
    )
    set_tests_properties(${TST_NAME} PROPERTIES ENVIRONMENT "QT_QPA_FONTDIR=${CMAKE_BINARY_DIR}")
endmacro()

if(QMLTESTRUNNER_BIN AND XVFB_RUN_BIN)
    declare_qml_test("keypad_button" tst_KeypadButton.qml)
    declare_qml_test("main_view" tst_MainView.qml)
    declare_qml_test("stopwatch" tst_StopWatch.qml)
    declare_qml_test("dialer_page" tst_DialerPage.qml)
else()
    if (NOT QMLTESTRUNNER_BIN)
        message(WARNING "Qml tests disabled: qmltestrunner not found")
    else()
        message(WARNING "Qml tests disabled: xvfb-run not found")
    endif()
endif()

set(QML_TST_FILES
    tst_KeypadButton.qml
    tst_StopWatch.qml
    tst_MainView.qml
    tst_DialerPage.qml
)
add_custom_target(tst_QmlFiles ALL SOURCES ${QML_TST_FILES})
