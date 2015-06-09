execute_process(COMMAND python3 -c "from distutils.sysconfig import get_python_lib; print (get_python_lib())"
    OUTPUT_VARIABLE PYTHON_PACKAGE_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)

add_subdirectory(qml)
add_subdirectory(data)
add_subdirectory(autopilot)
