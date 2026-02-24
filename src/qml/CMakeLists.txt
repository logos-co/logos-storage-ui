cmake_minimum_required(VERSION 3.16)

project(qml VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

########### DEPENDENCIES ###########

# This section locates the required dependencies in 3 different ways:
# 1- With NIX, the root folders (LOGOS_LIBLOGOS_ROOT, LOGOS_CPP_SDK_ROO)
#    are defined and point to the correct locations in
#    the Nix store.
# 2- If the root folders are fetched from source (basically using git) in the
#    parent folder, this is detected and used.
# 3- If none of the above apply, the vendor folders inside this project are used,
#    meaning the dependencies need to be fetched using git submodules.

# Locate logos-cpp-sdk
if(NOT DEFINED LOGOS_CPP_SDK_ROOT)
    set(_parent_cpp_sdk "${CMAKE_SOURCE_DIR}/../../../logos-cpp-sdk")
    set(_use_vendor ${LOGOS_STORAGE_UI_USE_VENDOR})

    if(NOT _use_vendor)
        if(NOT EXISTS "${_parent_cpp_sdk}/cpp/logos_api.h")
            set(_use_vendor ON)
        endif()
    endif()

    if(_use_vendor)
        set(LOGOS_CPP_SDK_ROOT "${CMAKE_SOURCE_DIR}/../../vendor/logos-cpp-sdk")
    else()
        set(LOGOS_CPP_SDK_ROOT "${_parent_cpp_sdk}")
    endif()
endif()

if(NOT DEFINED LOGOS_DESIGN_SYSTEM_ROOT)
    set(_parent_logos_design_system "${CMAKE_SOURCE_DIR}/../../../logos-design-system")
    set(_use_vendor ${LOGOS_STORAGE_UI_USE_VENDOR})

    if(NOT _use_vendor)
        if(NOT EXISTS "${_parent_logos_design_system}/CMakeLists.txt")
            set(_use_vendor ON)
        endif()
    endif()

    if(_use_vendor)
        set(LOGOS_DESIGN_SYSTEM_ROOT "${CMAKE_SOURCE_DIR}/../../vendor/logos-design-system")
    else()
        set(LOGOS_DESIGN_SYSTEM_ROOT "${_parent_logos_design_system}")
    endif()
endif()

# Locate the logos_api header file.
# If the file is found, the sdk is considered found.
set(_cpp_sdk_found FALSE)
if(EXISTS "${LOGOS_CPP_SDK_ROOT}/cpp/logos_api.h")
    set(_cpp_sdk_found TRUE)
    set(_cpp_sdk_is_source TRUE)
elseif(EXISTS "${LOGOS_CPP_SDK_ROOT}/include/cpp/logos_api.h")
    set(_cpp_sdk_found TRUE)
    set(_cpp_sdk_is_source FALSE)
endif()

# Fails if the SDK is not found.
if(NOT _cpp_sdk_found)
    message(FATAL_ERROR
        "logos-cpp-sdk not found at ${LOGOS_CPP_SDK_ROOT}. "
        "Set LOGOS_CPP_SDK_ROOT or run git submodule update --init --recursive."
    )
endif()

########### DEPENDENCIES END ###########

########### QML DEFINITION ###########

set(PLUGIN_UI_BUILD_DIR "../../build/generated_code")

list(APPEND SOURCES
    ${PLUGIN_UI_BUILD_DIR}/logos_sdk.cpp
)

# Create a library with the Logos SDK and generated sources to keep them separate
add_library(storage_generated STATIC
    ${PLUGIN_UI_BUILD_DIR}/logos_sdk.cpp
    ${PLUGIN_UI_BUILD_DIR}/storage_module_api.cpp
    ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api.cpp
    ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api_client.cpp
    ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api_provider.cpp
    ${LOGOS_CPP_SDK_ROOT}/cpp/module_proxy.cpp
    ${LOGOS_CPP_SDK_ROOT}/cpp/token_manager.cpp
    ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api_consumer.cpp
    ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api_provider.cpp
    ${LOGOS_CPP_SDK_ROOT}/cpp/logos_types.cpp
)

# Define the dependencies needed for storage_generated
target_link_libraries(storage_generated PUBLIC
    Qt6::Core
    Qt6::RemoteObjects
)

# Discover the required dependencies
find_package(Qt6 REQUIRED COMPONENTS Quick RemoteObjects)

# Standard project setup for Qt applications
qt_standard_project_setup(REQUIRES 6.8)

# Add the Qt Quick application executable
qt_add_executable(appqml
    main.cpp
)

# Use these required dependencies.
target_link_libraries(appqml PRIVATE
    Qt6::Quick
    Qt6::Qml
    storage_generated
)

# Define the qml module and the StorageBackend sources.
set_source_files_properties(MockBackend.qml PROPERTIES QML_SINGLETON TRUE)

qt_add_qml_module(appqml
    URI StorageBackend
    VERSION 1.0
    SOURCES
        ../StorageBackend.cpp
        ../StorageBackend.h
    QML_FILES
        StorageView.qml
        OnBoarding.qml
        Main.qml
        StartNode.qml
        LogosTextField.qml
        LogosStorageButton.qml
        LogosStorageLayout.qml
        PortForwarding.qml
        ErrorToast.qml
        HealthIndicator.qml
        ModeSelector.qml
        AdvancedSetup.qml
        icons/DotIcon.qml
        icons/NodeStatusIcon.qml
        icons/GuideIcon.qml
        icons/AdvancedIcon.qml
        icons/UpnpIcon.qml
        icons/PortIcon.qml
        icons/StorageIcon.qml
        icons/PlayIcon.qml
        icons/StopIcon.qml
        icons/SettingsIcon.qml
        icons/UploadIcon.qml
        icons/DownloadIcon.qml
        icons/DeleteIcon.qml
        icons/ArcWidget.qml
        DiskWidget.qml
        UploadWidget.qml
        PeersWidget.qml
        JsonEditor.qml
        SettingsPopup.qml
        ManifestTable.qml
        NodeHeader.qml
        Widgets.qml
        DebugPanel.qml
        Utils.js
        MockBackend.qml
        OnBoardingLayout.qml
        OnBoardingHeader.qml
        OnBoardingProgress.qml
        OnBoardingCard.qml
        assets/bg.png
        assets/badge_alpha.png
        assets/alpha.png
        assets/arrow-right.png
        RESOURCES

)

# Set up QML module directory for runtime
set(DESIGN_SYSTEM_QML ${LOGOS_DESIGN_SYSTEM_ROOT}/src/qml)
set(QML_THEME_DIR ${CMAKE_CURRENT_BINARY_DIR}/qml/Logos/Theme)
set(QML_CONTROLS_DIR ${CMAKE_CURRENT_BINARY_DIR}/qml/Logos/Controls)

# Copy QML module files to runtime directory
# Pure QML module - no library, just QML files + qmldir
add_custom_command(TARGET storage_generated POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${QML_THEME_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${DESIGN_SYSTEM_QML}/theme/ ${QML_THEME_DIR}/
    COMMAND ${CMAKE_COMMAND} -E make_directory ${QML_CONTROLS_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${DESIGN_SYSTEM_QML}/controls/ ${QML_CONTROLS_DIR}/
    COMMENT "Setting up Logos.Theme and Logos.Controls QML modules for the app"
)

########### QML DEFINITION END ###########

########### HEADERS ###########

target_include_directories(storage_generated PUBLIC
    "${PLUGIN_UI_BUILD_DIR}"
    "${PLUGIN_UI_BUILD_DIR}/include"
)

# Include directories
if(_cpp_sdk_is_source)
    target_include_directories(storage_generated PUBLIC
        ${LOGOS_CPP_SDK_ROOT}/cpp
        ${LOGOS_CPP_SDK_ROOT}/cpp/generated
    )
else()
    target_include_directories(storage_generated PUBLIC
        ${LOGOS_CPP_SDK_ROOT}/include
        ${LOGOS_CPP_SDK_ROOT}/include/cpp
        ${LOGOS_CPP_SDK_ROOT}/include/core
        ${PLUGIN_UI_BUILD_DIR}/include
    )
endif()

# Import the application headers.
target_include_directories(appqml PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/..
    ${PLUGINS_OUTPUT_DIR}
)

########### HEADERS END ###########

message(STATUS "Qt Quick app configured successfully")
