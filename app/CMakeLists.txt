cmake_minimum_required(VERSION 3.16)
project(LogosStorageUIApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

########### DEPENDENCIES ###########

if(NOT DEFINED LOGOS_LIBLOGOS_ROOT AND DEFINED ENV{LOGOS_LIBLOGOS_ROOT})
    set(LOGOS_LIBLOGOS_ROOT "$ENV{LOGOS_LIBLOGOS_ROOT}")
endif()

if(NOT DEFINED LOGOS_CPP_SDK_ROOT AND DEFINED ENV{LOGOS_CPP_SDK_ROOT})
    set(LOGOS_CPP_SDK_ROOT "$ENV{LOGOS_CPP_SDK_ROOT}")
endif()

if(NOT EXISTS "${LOGOS_LIBLOGOS_ROOT}/include/core/interface.h")
    message(FATAL_ERROR "logos-liblogos not found at ${LOGOS_LIBLOGOS_ROOT}. "
                        "Set LOGOS_LIBLOGOS_ROOT.")
endif()

if(NOT EXISTS "${LOGOS_CPP_SDK_ROOT}/include/cpp/logos_api.h")
    message(FATAL_ERROR "logos-cpp-sdk not found at ${LOGOS_CPP_SDK_ROOT}. "
                        "Set LOGOS_CPP_SDK_ROOT.")
endif()

message(STATUS "Using logos-liblogos at: ${LOGOS_LIBLOGOS_ROOT}")
message(STATUS "Using logos-cpp-sdk at: ${LOGOS_CPP_SDK_ROOT}")

########### DEPENDENCIES END ###########

########### APP DEFINITION ###########

# Find Qt packages
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Widgets)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Widgets)

# Link directories
link_directories(
    ${LOGOS_LIBLOGOS_ROOT}/lib
    ${LOGOS_CPP_SDK_ROOT}/lib
)

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Create the executable
add_executable(logos-storage-ui-app
    main.cpp
    mainwindow.cpp
    mainwindow.h
)

# Link libraries
target_link_libraries(logos-storage-ui-app PRIVATE
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Widgets
    logos_core
    logos_sdk
)

########### APP DEFINITION END ###########

########### HEADERS ###########

# Include directories - the new structure has headers in /include with subdirectories
include_directories(
    ${LOGOS_LIBLOGOS_ROOT}/include
    ${LOGOS_CPP_SDK_ROOT}/include
    ${LOGOS_CPP_SDK_ROOT}/include/cpp
    ${LOGOS_CPP_SDK_ROOT}/include/core
)

########### HEADERS END ###########

########### RUNTIME LINKS ###########

# Set RPATH settings for the executable
if(APPLE)
    set_target_properties(logos-storage-ui-app PROPERTIES
        INSTALL_RPATH "@executable_path/../lib"
        BUILD_WITH_INSTALL_RPATH TRUE
    )
elseif(UNIX)
    set_target_properties(logos-storage-ui-app PROPERTIES
        INSTALL_RPATH "$ORIGIN/../lib"
        BUILD_WITH_INSTALL_RPATH TRUE
    )
endif()

########### RUNTIME LINKS END ###########

########### INSTALL ###########

# Install rules
install(TARGETS logos-storage-ui-app
    RUNTIME DESTINATION bin
)

########### INSTALL END ###########
