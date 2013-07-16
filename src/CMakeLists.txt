set(DIALER_APP dialer-app)

set(dialer_app_HDRS
    dialerapplication.h
    dialerappdbus.h)

set(dialer_app_SRCS
    dialerapplication.cpp
    dialerappdbus.cpp
    main.cpp)

qt5_add_dbus_adaptor(dialer_app_SRCS DialerApp.xml dialerappdbus.h DialerAppDBus)
add_executable(${DIALER_APP}
    ${dialer_app_SRCS}
    )
qt5_use_modules(${DIALER_APP} Core DBus Gui Qml Quick)

include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}
    )

install(TARGETS ${DIALER_APP}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )


configure_file(com.canonical.DialerApp.service.in com.canonical.DialerApp.service)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/com.canonical.DialerApp.service DESTINATION share/dbus-1/services)

# Handle i18n in the desktop file
set(DESKTOP_FILE ${DIALER_APP}.desktop)
file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE})
file(STRINGS ${DESKTOP_FILE}.in DESKTOP_FILE_CONTENTS)
foreach(LINE ${DESKTOP_FILE_CONTENTS})
    string(REGEX REPLACE "tr\\\(\"(.*)\"\\\)" "\\1" LINE "${LINE}")
    file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE} "${LINE}\n")
endforeach(LINE)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
    )

add_subdirectory(qml)
