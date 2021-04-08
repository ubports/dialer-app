find_package(Qt5Core REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5QuickTest REQUIRED)
find_package(Qt5Contacts REQUIRED)

set(TEST tst_QmlTests)
set(XVFB_COMMAND)

find_program(XVFB_RUN_BIN
    NAMES xvfb-run
)

if(XVFB_RUN_BIN)
    set(XVFB_COMMAND ${XVFB_RUN_BIN} -s "-screen 0 1024x768x24" -a)
else()
    message(WARNING "Qml tests disabled: xvfb-run not found")
endif()

set(SOURCE_DIR ${dialer-app_SOURCE_DIR}/src)
set(SOURCES
    ${SOURCE_DIR}/dialpadsearch.cpp
    #${SOURCE_DIR}/dialpadsearch.h
    ${SOURCE_DIR}/contactutils.cpp
    #${SOURCE_DIR}/contactutils.h
)

set(QmlTest_SOURCES
    ${SOURCES}
    tst_QmlTests.cpp
    )

include_directories(
    ${dialer-app_SOURCE_DIR}/src
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}
)

#QML tests
macro(DECLARE_QML_TEST TST_NAME TST_QML_FILE)
    add_test(${TST_NAME} ${XVFB_COMMAND} ${CMAKE_CURRENT_BINARY_DIR}/${TEST}
        -import ${CMAKE_BINARY_DIR}/src
        -input ${CMAKE_CURRENT_SOURCE_DIR}/${TST_QML_FILE}
    )
endmacro()


add_executable(${TEST} ${QmlTest_SOURCES})
qt5_use_modules(${TEST} Core Qml Quick QuickTest Contacts)


declare_qml_test(KeypadButton tst_KeypadButton.qml)
declare_qml_test(MainView tst_MainView.qml)
declare_qml_test(StopWatch tst_StopWatch.qml)
declare_qml_test(HistoryDelegate tst_HistoryDelegate.qml)
declare_qml_test(DialerPage tst_DialerPage.qml)
declare_qml_test(DialPadSearch tst_DialPadSearch.qml)

# make qml files visible in QtCreator
file(GLOB_RECURSE QML_TST_FILES *.qml)
add_custom_target(tst_QmlFiles ALL SOURCES ${QML_TST_FILES})
