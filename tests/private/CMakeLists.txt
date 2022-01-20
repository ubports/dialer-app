find_package(Qt5Core REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5QuickTest REQUIRED)
find_package(Qt5Contacts REQUIRED)

set(SOURCE_DIR ${dialer-app_SOURCE_DIR}/src)
set(SOURCES
    ${SOURCE_DIR}/dialpadsearch.cpp
    ${SOURCE_DIR}/contactutils.cpp
)

set(DialerAppTest_SOURCES
    ${SOURCES}
    DialPadSearchTest.cpp
    )

include_directories(
    ${dialer-app_SOURCE_DIR}/src
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}
)

add_executable(DialPadSearchTest ${DialerAppTest_SOURCES})
add_test(DialPadSearchTest ${CMAKE_CURRENT_BINARY_DIR}/DialPadSearchTest)
target_link_libraries(DialPadSearchTest Qt5::Core Qt5::Contacts Qt5::Test)
