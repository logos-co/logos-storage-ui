cmake_minimum_required(VERSION 3.16)
project(StorageUIPlugin VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

########### DEPENDENCIES SECTION ###########

# This section locates the required dependencies in 3 different ways:
# 1- With NIX, the root folders (LOGOS_LIBLOGOS_ROOT, LOGOS_CPP_SDK_ROOT,
#    and LOGOS_STORAGE_ROOT) are defined and point to the correct locations in
#    the Nix store.
# 2- If the root folders are fetched from source (basically using git) in the
#    parent folder, this is detected and used.
# 3- If none of the above apply, the vendor folders inside this project are used,
#    meaning the dependencies need to be fetched using git submodules.

if(NOT DEFINED LOGOS_LIBLOGOS_ROOT)
    set(_parent_liblogos "${CMAKE_SOURCE_DIR}/../logos-liblogos")
    set(_use_vendor ${LOGOS_STORAGE_UI_USE_VENDOR})
    if(NOT _use_vendor)
        if(NOT EXISTS "${_parent_liblogos}/src/common/interface.h")
            set(_use_vendor ON)
        endif()
    endif()
    if(_use_vendor)
        set(LOGOS_LIBLOGOS_ROOT "${CMAKE_SOURCE_DIR}/vendor/logos-liblogos")
    else()
        set(LOGOS_LIBLOGOS_ROOT "${_parent_liblogos}")
    endif()
endif()

if(NOT DEFINED LOGOS_CPP_SDK_ROOT)
    set(_parent_cpp_sdk "${CMAKE_SOURCE_DIR}/../logos-cpp-sdk")
    set(_use_vendor ${LOGOS_STORAGE_UI_USE_VENDOR})
    if(NOT _use_vendor)
        if(NOT EXISTS "${_parent_cpp_sdk}/cpp/logos_api.h")
            set(_use_vendor ON)
        endif()
    endif()
    if(_use_vendor)
        set(LOGOS_CPP_SDK_ROOT "${CMAKE_SOURCE_DIR}/vendor/logos-cpp-sdk")
    else()
        set(LOGOS_CPP_SDK_ROOT "${_parent_cpp_sdk}")
    endif()
endif()

if(NOT DEFINED LOGOS_STORAGE_ROOT)
    set(_parent_storage_module "${CMAKE_SOURCE_DIR}/../logos-storage-module")
    set(_use_vendor ${LOGOS_STORAGE_UI_USE_VENDOR})
    if(NOT _use_vendor)
        if(NOT EXISTS "${_parent_storage_module}/storage_module_plugin.h")
            set(_use_vendor ON)
        endif()
    endif()
    if(_use_vendor)
        set(LOGOS_STORAGE_ROOT "${CMAKE_SOURCE_DIR}/vendor/logos-storage-module")
    else()
        set(LOGOS_STORAGE_ROOT "${_parent_storage_module}")
    endif()
endif()

if(NOT DEFINED LOGOS_DESIGN_SYSTEM_ROOT)
    set(_parent_logos_design_system "${CMAKE_SOURCE_DIR}/../logos-design-system")
    set(_use_vendor ${LOGOS_STORAGE_UI_USE_VENDOR})

    if(NOT _use_vendor)
        if(NOT EXISTS "${_parent_logos_design_system}/CMakeLists.txt")
            set(_use_vendor ON)
        endif()
    endif()

    if(_use_vendor)
        set(LOGOS_DESIGN_SYSTEM_ROOT "${CMAKE_SOURCE_DIR}/vendor/logos-design-system")
    else()
        set(LOGOS_DESIGN_SYSTEM_ROOT "${_parent_logos_design_system}")
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

set(_storage_module_found FALSE)
if(EXISTS "${LOGOS_STORAGE_ROOT}/storage_module_plugin.h")
    set(_storage_module_found TRUE)
    set(_storage_module_is_source TRUE)
elseif(EXISTS "${LOGOS_STORAGE_ROOT}/include/storage_module_api.h")
    set(_storage_module_found TRUE)
    set(_storage_module_is_source FALSE)
endif()

if(NOT _liblogos_found)
    message(FATAL_ERROR "logos-liblogos not found at ${LOGOS_LIBLOGOS_ROOT}. "
                        "Set LOGOS_LIBLOGOS_ROOT or run git submodule update --init --recursive.")
endif()

if(NOT _cpp_sdk_found)
    message(FATAL_ERROR "logos-cpp-sdk not found at ${LOGOS_CPP_SDK_ROOT}. "
                        "Set LOGOS_CPP_SDK_ROOT or run git submodule update --init --recursive.")
endif()

if(NOT _storage_module_found)
    message(FATAL_ERROR "logos-storage-module not found at ${LOGOS_STORAGE_ROOT}. "
                        "Set LOGOS_STORAGE_ROOT or run git submodule update --init --recursive.")
endif()

########### DEPENDENCIES END ###########

########### QT SECTION ###########

# Discover the required dependencies.
# Without this discovery part, the dependencies cannot be found.
# COMPONENTS is kind of generic for Qt modules.
find_package(Qt6 REQUIRED COMPONENTS Core Widgets RemoteObjects Quick QuickWidgets Network)

# Get the real path to handle symlinks correctly
#get_filename_component(REAL_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}" REALPATH)

# Try to find the component-interfaces package first
find_package(component-interfaces QUIET)

# If not found, use the local interfaces folder
if(NOT component-interfaces_FOUND)
    # Include the local interfaces directory
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/interfaces)
    
    # Create a component-interfaces library
    add_library(component-interfaces INTERFACE)
    target_include_directories(component-interfaces INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/interfaces)
endif()

########### QT SECTION END ###########

########### SOURCES ###########

# Source files
set(SOURCES
    src/StorageUIPlugin.cpp
    src/StorageUIPlugin.h
    src/StorageBackend.cpp
    src/StorageBackend.h
    src/storage_resources.qrc
)

# Add SDK sources (only if source layout, installed layout uses the library)
if(_cpp_sdk_is_source)
    list(APPEND SOURCES
        ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api.cpp
        ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api.h
        ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api_client.cpp
        ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api_client.h
        ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api_consumer.cpp
        ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api_consumer.h
        ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api_provider.cpp
        ${LOGOS_CPP_SDK_ROOT}/cpp/logos_api_provider.h
        ${LOGOS_CPP_SDK_ROOT}/cpp/token_manager.cpp
        ${LOGOS_CPP_SDK_ROOT}/cpp/token_manager.h
        ${LOGOS_CPP_SDK_ROOT}/cpp/module_proxy.cpp
        ${LOGOS_CPP_SDK_ROOT}/cpp/module_proxy.h
        ${LOGOS_CPP_SDK_ROOT}/cpp/logos_types.cpp
        ${LOGOS_CPP_SDK_ROOT}/cpp/logos_types.h
    )
endif()

########### SOURCES END ###########

########### CPP GENERATOR ###########

# Define metadata json path
set(METADATA_JSON "${CMAKE_CURRENT_SOURCE_DIR}/metadata.json")

# If the storage module is from source,
# run the cpp generator to generate storage_module_api.cpp.
# Only run generator for source layout - nix builds already have generated files.
if(_storage_module_is_source)
    # Define the output directory for generated code
    set(PLUGINS_OUTPUT_DIR "${CMAKE_BINARY_DIR}/generated_code")

    # Ensure output directory exists
    set(CPP_GENERATOR_BUILD_DIR "${LOGOS_CPP_SDK_ROOT}/../build/cpp-generator")

    # Define path to cpp generator executable
    set(CPP_GENERATOR "${CPP_GENERATOR_BUILD_DIR}/bin/logos-cpp-generator")

    # Build the cpp generator if not already built
    if(NOT TARGET cpp_generator_build)
        add_custom_target(cpp_generator_build
            COMMAND bash "${LOGOS_CPP_SDK_ROOT}/cpp-generator/compile.sh"
            WORKING_DIRECTORY "${LOGOS_CPP_SDK_ROOT}/.."
            COMMENT "Building logos-cpp-generator via ${LOGOS_CPP_SDK_ROOT}/cpp-generator/compile.sh"
            VERBATIM
        )
    endif()

    # Add a custom target to build the storage module first and produce
    # the so file or the dylib file
    add_custom_target(run_build_storage_module
        COMMAND "${CMAKE_COMMAND}" -S "${LOGOS_STORAGE_ROOT}" -B "${LOGOS_STORAGE_ROOT}/build"
        COMMAND "${CMAKE_COMMAND}" --build "${LOGOS_STORAGE_ROOT}/build" --target all
        WORKING_DIRECTORY "${LOGOS_STORAGE_ROOT}/.."
        COMMENT "Building storage module in ${LOGOS_STORAGE_ROOT}/build"
        VERBATIM
    )

    # Ensure storage module is built before running cpp generator
    if(APPLE)
      set(PLUGIN_FILE "${LOGOS_STORAGE_ROOT}/build/modules/storage_module_plugin.dylib")
    elseif(UNIX)
      set(PLUGIN_FILE "${LOGOS_STORAGE_ROOT}/build/modules/storage_module_plugin.so")
    else()
        message(FATAL_ERROR "storage_module_plugin is not found.")
    endif()

    # Add custom target to run the cpp generator for the storage module
    add_custom_target(run_cpp_generator_storage_module
        COMMAND "${CPP_GENERATOR}" "${PLUGIN_FILE}" --interface "${LOGOS_STORAGE_ROOT}/storage_module_interface.h" --module-only --output-dir "${PLUGINS_OUTPUT_DIR}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        COMMENT "Running logos-cpp-generator on ${PLUGIN_FILE} with output-dir ${PLUGINS_OUTPUT_DIR}"
        VERBATIM
    )

    # Make sure that we build the storage module after running the cpp generator
    add_dependencies(run_cpp_generator_storage_module cpp_generator_build)
    add_dependencies(run_cpp_generator_storage_module run_build_storage_module)
endif()

# Only run generator for source layout - nix builds already have generated files
if(_cpp_sdk_is_source)
    if(NOT DEFINED PLUGINS_OUTPUT_DIR)
        # Define the output directory for generated code
        set(PLUGINS_OUTPUT_DIR "${CMAKE_BINARY_DIR}/generated_code")
    endif()

    if(NOT DEFINED CPP_GENERATOR_BUILD_DIR)
        # Ensure output directory exists
        set(CPP_GENERATOR_BUILD_DIR "${LOGOS_CPP_SDK_ROOT}/../build/cpp-generator")
    endif()

    if(NOT DEFINED CPP_GENERATOR)
        # Define path to cpp generator executable
        set(CPP_GENERATOR "${CPP_GENERATOR_BUILD_DIR}/bin/logos-cpp-generator")
    endif()

    # Build the cpp generator if not already built
    if(NOT TARGET cpp_generator_build)
        add_custom_target(cpp_generator_build
            COMMAND bash "${LOGOS_CPP_SDK_ROOT}/cpp-generator/compile.sh"
            WORKING_DIRECTORY "${LOGOS_CPP_SDK_ROOT}/.."
            COMMENT "Building logos-cpp-generator via ${LOGOS_CPP_SDK_ROOT}/cpp-generator/compile.sh"
            VERBATIM
        )
    endif()

    add_custom_command(
      OUTPUT "${PLUGINS_OUTPUT_DIR}/logos_sdk.cpp"
      COMMAND ${CMAKE_COMMAND} -E make_directory "${PLUGINS_OUTPUT_DIR}"
      COMMAND "${CPP_GENERATOR}" --metadata "${METADATA_JSON}" --general-only --output-dir "${PLUGINS_OUTPUT_DIR}"
      WORKING_DIRECTORY "${LOGOS_CPP_SDK_ROOT}/.."
      DEPENDS "${METADATA_JSON}" cpp_generator_build
      VERBATIM
    )

    add_custom_target(run_cpp_generator_storage_ui DEPENDS "${PLUGINS_OUTPUT_DIR}/logos_sdk.cpp")

    # Add generated logos_sdk.cpp - will be generated by run_cpp_generator_storage_ui
    list(APPEND SOURCES
            ${PLUGINS_OUTPUT_DIR}/logos_sdk.cpp
    )

    # Mark as generated so CMake knows to wait for it
    set_source_files_properties(
        ${PLUGINS_OUTPUT_DIR}/logos_sdk.cpp
        PROPERTIES GENERATED TRUE
    )
else()
    # Define the output directory for generated code
    set(PLUGINS_OUTPUT_DIR "${CMAKE_SOURCE_DIR}/generated_code")

    # For installed/nix layout, logos_sdk.cpp is already in ${PLUGINS_OUTPUT_DIR}
    # (generated by nix build preConfigure phase in lib.nix before CMake runs)
    list(APPEND SOURCES ${PLUGINS_OUTPUT_DIR}/logos_sdk.cpp)
endif()

########### CPP GENERATOR END ###########

########### LIBRARY DEFINITION ###########

# Create the plugin library.
# This lib is the lib to be shared in order to
# be integrated in a standalone application.
add_library(storage_ui SHARED ${SOURCES})

# Set output name without lib prefix and with correct name for generator
set_target_properties(storage_ui PROPERTIES
    PREFIX ""
    OUTPUT_NAME "storage_ui"
)

# Ensure generator runs before building the plugin (only for source layout)
if(_cpp_sdk_is_source)
   add_dependencies(storage_ui run_cpp_generator_storage_ui)
endif()

if(_storage_module_is_source)
   add_dependencies(storage_ui run_cpp_generator_storage_module)
endif()

# Set common properties for both platforms
set_target_properties(storage_ui PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/modules"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/modules"  # For Windows .dll
    BUILD_WITH_INSTALL_RPATH TRUE
    SKIP_BUILD_RPATH FALSE)

# Link SDK library if using installed layout
if(NOT _cpp_sdk_is_source)
    find_library(LOGOS_SDK_LIB logos_sdk PATHS ${LOGOS_CPP_SDK_ROOT}/lib NO_DEFAULT_PATH REQUIRED)
    target_link_libraries(storage_ui PRIVATE ${LOGOS_SDK_LIB})
endif()

# Link against Abseil libraries if found
find_package(absl QUIET)
if(absl_FOUND)
    target_link_libraries(storage_ui PRIVATE
        absl::base
        absl::strings
        absl::log
        absl::check
    )
endif()

# Set up QML module directory for runtime
set(QML_THEME_DIR ${CMAKE_CURRENT_BINARY_DIR}/qml/Logos/Theme)
set(QML_CONTROLS_DIR ${CMAKE_CURRENT_BINARY_DIR}/qml/Logos/Controls)

# Detect if design system is source or installed layout
set(_design_system_is_source FALSE)
if(EXISTS "${LOGOS_DESIGN_SYSTEM_ROOT}/src/qml/theme")
    set(_design_system_is_source TRUE)
    set(DESIGN_SYSTEM_THEME_SRC "${LOGOS_DESIGN_SYSTEM_ROOT}/src/qml/theme")
    set(DESIGN_SYSTEM_CONTROLS_SRC "${LOGOS_DESIGN_SYSTEM_ROOT}/src/qml/controls")
else()
    # Installed/Nix layout: files are in lib/Logos/Theme and lib/Logos/Controls
    set(DESIGN_SYSTEM_THEME_SRC "${LOGOS_DESIGN_SYSTEM_ROOT}/lib/Logos/Theme")
    set(DESIGN_SYSTEM_CONTROLS_SRC "${LOGOS_DESIGN_SYSTEM_ROOT}/lib/Logos/Controls")
endif()

# Copy QML module files to runtime directory
# Pure QML module - no library, just QML files + qmldir
add_custom_command(TARGET storage_ui POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${QML_THEME_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${DESIGN_SYSTEM_THEME_SRC}/ ${QML_THEME_DIR}/
    COMMAND ${CMAKE_COMMAND} -E make_directory ${QML_CONTROLS_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${DESIGN_SYSTEM_CONTROLS_SRC}/ ${QML_CONTROLS_DIR}/
    COMMENT "Setting up Logos.Theme and Logos.Controls QML modules for the app"
)

########### LIBRARY DEFINITION END ###########

########### HEADERS ###########

# Include directories
target_include_directories(storage_ui PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${PLUGINS_OUTPUT_DIR}
)

# Add include directories based on layout type
if(_liblogos_is_source)
    target_include_directories(storage_ui PRIVATE ${LOGOS_LIBLOGOS_ROOT})
else()
    target_include_directories(storage_ui PRIVATE ${LOGOS_LIBLOGOS_ROOT}/include)
endif()

if(_cpp_sdk_is_source)
    target_include_directories(storage_ui PRIVATE

        #${PLUGINS_OUTPUT_DIR}
        ${LOGOS_CPP_SDK_ROOT}/cpp
        ${LOGOS_CPP_SDK_ROOT}/cpp/generated
    )
else()
    # For nix builds, also include the include subdirectory
    # (lib.nix moves header files to ./generated_code/include/)
    target_include_directories(storage_ui PRIVATE
        ${LOGOS_CPP_SDK_ROOT}/include
        ${LOGOS_CPP_SDK_ROOT}/include/cpp
        ${LOGOS_CPP_SDK_ROOT}/include/core
        ${PLUGINS_OUTPUT_DIR}/include
    )
endif()

########### HEADERS END ###########

########### LINKS ###########

# Link against libraries
target_link_libraries(storage_ui PRIVATE 
    Qt6::Core
    Qt6::Widgets
    Qt6::RemoteObjects
    Qt6::Quick
    Qt6::QuickWidgets
    Qt6::Network
    component-interfaces
)

########### RUNTIME LINK ###########

if(APPLE)
    # macOS specific settings
    set_target_properties(storage_ui PROPERTIES
        INSTALL_RPATH "@loader_path"
        INSTALL_NAME_DIR "@rpath"
        BUILD_WITH_INSTALL_NAME_DIR TRUE)
    
    add_custom_command(TARGET storage_ui POST_BUILD
        COMMAND install_name_tool -id "@rpath/storage_ui.dylib" $<TARGET_FILE:storage_ui>
        COMMENT "Updating library paths for macOS"
    )
else()
    # Linux specific settings
    set_target_properties(storage_ui PROPERTIES
        INSTALL_RPATH "$ORIGIN"
        INSTALL_RPATH_USE_LINK_PATH FALSE)
endif()

########### RUNTIME LINK END ###########

########### INSTALL ###########

install(TARGETS storage_ui
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/logos/modules
    RUNTIME DESTINATION ${CMAKE_INSTALL_LIBDIR}/logos/modules
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}/logos/modules
)

install(FILES ${METADATA_JSON}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/logos-storage-ui
)

install(DIRECTORY "${PLUGINS_OUTPUT_DIR}/"
    DESTINATION ${CMAKE_INSTALL_DATADIR}/logos-storage-ui/generated
    OPTIONAL
)

########### INSTALL END ###########

# Print status messages
message(STATUS "Storage UI Plugin configured successfully") 
