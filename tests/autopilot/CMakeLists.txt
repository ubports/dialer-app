set(AUTOPILOT_DIR dialer_app)

execute_process(COMMAND python3 -c "from distutils.sysconfig import get_python_lib; print (get_python_lib())"
    OUTPUT_VARIABLE PYTHON_PACKAGE_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)

install(DIRECTORY ${AUTOPILOT_DIR}
    DESTINATION ${PYTHON_PACKAGE_DIR}
    )

add_custom_target(test-autopilot
    BUILD_DIR=${CMAKE_BINARY_DIR} autopilot3 run -v ${AUTOPILOT_DIR}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
