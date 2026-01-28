cmake_minimum_required(VERSION 3.16)
project(LogosStorageUIApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

########### DEPENDENCIES ###########

# This section locates the required dependencies in 3 different ways:
# 1- With NIX, the root folders (LOGOS_LIBLOGOS_ROOT, LOGOS_CPP_SDK_ROOT)
#    are defined and point to the correct locations in
#    the Nix store.
# 2- If the root folders are fetched from source (basically using git) in the
#    parent folder, this is detected and used.
# 3- If none of the above apply, the vendor folders inside this project are used,
#    meaning the dependencies need to be fetched using git submodules.

if(NOT DEFINED LOGOS_LIBLOGOS_ROOT)
    set(_parent_liblogos "${CMAKE_SOURCE_DIR}/../../logos-liblogos")
    set(_use_vendor ${LOGOS_STORAGE_UI_USE_VENDOR})
    if(NOT _use_vendor)
        if(NOT EXISTS "${_parent_liblogos}/src/common/interface.h")
            set(_use_vendor ON)
        endif()
    endif()
    if(_use_vendor)
        set(LOGOS_LIBLOGOS_ROOT "${CMAKE_SOURCE_DIR}/../vendor/logos-liblogos")
    else()
        set(LOGOS_LIBLOGOS_ROOT "${_parent_liblogos}")
    endif()
endif()

if(NOT DEFINED LOGOS_CPP_SDK_ROOT)
    set(_parent_cpp_sdk "${CMAKE_SOURCE_DIR}/../../logos-cpp-sdk")
    set(_use_vendor ${LOGOS_STORAGE_UI_USE_VENDOR})
    if(NOT _use_vendor)
        if(NOT EXISTS "${_parent_cpp_sdk}/cpp/logos_api.h")
            set(_use_vendor ON)
        endif()
    endif()
    if(_use_vendor)
        set(LOGOS_CPP_SDK_ROOT "${CMAKE_SOURCE_DIR}/../vendor/logos-cpp-sdk")
    else()
        set(LOGOS_CPP_SDK_ROOT "${_parent_cpp_sdk}")
    endif()
endif()

set(_liblogos_found FALSE)
if(EXISTS "${LOGOS_LIBLOGOS_ROOT}/src/common/interface.h")
    set(_liblogos_found TRUE)
    set(_liblogos_is_source TRUE)
elseif(EXISTS "${LOGOS_LIBLOGOS_ROOT}/include/interface.h")
    set(_liblogos_found TRUE)
    set(_liblogos_is_source FALSE)
endif()

message(DEBUG "_liblogos_found ${_liblogos_found}")

set(_cpp_sdk_found FALSE)
if(EXISTS "${LOGOS_CPP_SDK_ROOT}/cpp/logos_api.h")
    set(_cpp_sdk_found TRUE)
    set(_cpp_sdk_is_source TRUE)
elseif(EXISTS "${LOGOS_CPP_SDK_ROOT}/include/cpp/logos_api.h")
    set(_cpp_sdk_found TRUE)
    set(_cpp_sdk_is_source FALSE)
endif()

if(NOT _liblogos_found)
    message(FATAL_ERROR "logos-liblogos not found at ${LOGOS_LIBLOGOS_ROOT}. "
                        "Set LOGOS_LIBLOGOS_ROOT or run git submodule update --init --recursive.")
endif()

if(NOT _cpp_sdk_found)
    message(FATAL_ERROR "logos-cpp-sdk not found at ${LOGOS_CPP_SDK_ROOT}. "
                        "Set LOGOS_CPP_SDK_ROOT or run git submodule update --init --recursive.")
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

########### LOGOS DEPENDENCIES LIBRARIES ###########

# Check if logos_sdk library exists
if(NOT EXISTS "${LOGOS_CPP_SDK_ROOT}/lib/liblogos_sdk.a" AND NOT EXISTS "${LOGOS_CPP_SDK_ROOT}/lib/liblogos_sdk.dylib" AND NOT EXISTS "${LOGOS_CPP_SDK_ROOT}/lib/liblogos_sdk.so")
    set(LOGOS_CPP_SDK_BUILD_DIR "${LOGOS_CPP_SDK_ROOT}/build")

    add_custom_target(run_build_cpp_sdk
        COMMAND ${CMAKE_COMMAND} -E make_directory "${LOGOS_CPP_SDK_BUILD_DIR}"
        COMMAND ${CMAKE_COMMAND} -E chdir "${LOGOS_CPP_SDK_BUILD_DIR}" cmake ../cpp -GNinja -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        COMMAND ${CMAKE_COMMAND} -E chdir "${LOGOS_CPP_SDK_BUILD_DIR}" ninja
        COMMAND ${CMAKE_COMMAND} -E make_directory "${LOGOS_CPP_SDK_ROOT}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${LOGOS_CPP_SDK_BUILD_DIR}/lib/liblogos_sdk.a"
                "${LOGOS_CPP_SDK_ROOT}/lib/liblogos_sdk.a"
        WORKING_DIRECTORY "${LOGOS_CPP_SDK_ROOT}"
        COMMENT "Build cpp sdk and copy liblogos_sdk.a to ${LOGOS_CPP_SDK_ROOT}/lib"
        VERBATIM
    )

    add_dependencies(logos-storage-ui-app run_build_cpp_sdk)
endif()

if(NOT EXISTS "${LOGOS_LIBLOGOS_ROOT}/lib/liblogos_core.a" AND NOT EXISTS "${LOGOS_LIBLOGOS_ROOT}/lib/liblogos_core.dylib" AND NOT EXISTS "${LOGOS_LIBLOGOS_ROOT}/lib/liblogos_core.so")
    set(LOGOS_LIBLOGOS_BUILD_DIR "${LOGOS_LIBLOGOS_ROOT}/build")

    add_custom_target(run_build_liblogos
      COMMAND ${CMAKE_COMMAND} -E make_directory "${LOGOS_LIBLOGOS_BUILD_DIR}"
      COMMAND ${CMAKE_COMMAND} -E chdir "${LOGOS_LIBLOGOS_BUILD_DIR}" cmake .. -GNinja -DCMAKE_POSITION_INDEPENDENT_CODE=ON
      COMMAND ${CMAKE_COMMAND} -E chdir "${LOGOS_LIBLOGOS_BUILD_DIR}" ninja
      COMMAND ${CMAKE_COMMAND} -E make_directory "${LOGOS_LIBLOGOS_ROOT}/lib"
      COMMAND ${CMAKE_COMMAND} -E copy_directory
              "${LOGOS_LIBLOGOS_BUILD_DIR}/lib"
              "${LOGOS_LIBLOGOS_ROOT}/lib"
      WORKING_DIRECTORY "${LOGOS_LIBLOGOS_ROOT}"
      COMMENT "Build logos-liblogos and copy liblogos_core.a to ${LOGOS_LIBLOGOS_ROOT}/lib"
      VERBATIM
    )

    add_dependencies(logos-storage-ui-app run_build_liblogos)
endif()

########### LOGOS DEPENDENCIES END ###########

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
