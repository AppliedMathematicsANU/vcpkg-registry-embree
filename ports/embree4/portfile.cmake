
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO RenderKit/embree
    REF v${VERSION}
    SHA512 5e77a033192ade6562b50d32c806c6a467580722898ca52ccfe002b51279314055e9c0e6c969651b0d03716d04ab249301340cd2790556a0dbfb8c296e8f0574
    HEAD_REF master
)

string(COMPARE EQUAL ${VCPKG_LIBRARY_LINKAGE} static EMBREE_STATIC_LIB)
string(COMPARE EQUAL ${VCPKG_CRT_LINKAGE} static EMBREE_STATIC_RUNTIME)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        backface-culling      EMBREE_BACKFACE_CULLING 
        compact-polys         EMBREE_COMPACT_POLYS   
        filter-function       EMBREE_FILTER_FUNCTION  
        ray-mask              EMBREE_RAY_MASK 
        ray-packets           EMBREE_RAY_PACKETS 

        geometry-triangle     EMBREE_GEOMETRY_TRIANGLE
        geometry-quad         EMBREE_GEOMETRY_QUAD
        geometry-curve        EMBREE_GEOMETRY_CURVE
        geometry-subdivision  EMBREE_GEOMETRY_SUBDIVISION
        geometry-user         EMBREE_GEOMETRY_USER
        geometry-instance     EMBREE_GEOMETRY_INSTANCE
        geometry-grid         EMBREE_GEOMETRY_GRID
        geometry-point        EMBREE_GEOMETRY_POINT
)

if("tasking-tbb" IN_LIST FEATURES)
    set(EMBREE_TASKING_SYSTEM "TBB")
else()
    set(EMBREE_TASKING_SYSTEM "INTERNAL")
endif()

vcpkg_replace_string("${SOURCE_PATH}/common/cmake/installTBB.cmake" "IF (EMBREE_STATIC_LIB)" "IF (0)")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS ${FEATURE_OPTIONS} ${EXTRA_OPTIONS}
        -DEMBREE_ISPC_SUPPORT=OFF
        -DEMBREE_TUTORIALS=OFF
        -DEMBREE_STATIC_RUNTIME=${EMBREE_STATIC_RUNTIME}
        -DEMBREE_STATIC_LIB=${EMBREE_STATIC_LIB}
        -DEMBREE_TASKING_SYSTEM:STRING=${EMBREE_TASKING_SYSTEM}
        -DEMBREE_INSTALL_DEPENDENCIES=OFF
    MAYBE_UNUSED_VARIABLES
        EMBREE_STATIC_RUNTIME
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/embree-${VERSION} PACKAGE_NAME embree)
set(config_file "${CURRENT_PACKAGES_DIR}/share/embree/embree-config.cmake")
# Fix details in config.
file(READ "${config_file}" contents)
string(REPLACE "SET(EMBREE_BUILD_TYPE Release)" "" contents "${contents}")
string(REPLACE "/../../../" "/../../" contents "${contents}")
string(REPLACE "FIND_PACKAGE" "include(CMakeFindDependencyMacro)\n  find_dependency" contents "${contents}")
string(REPLACE "REQUIRED" "COMPONENTS" contents "${contents}")
string(REPLACE "/lib/cmake/embree-${VERSION}" "/share/embree" contents "${contents}")

if(NOT VCPKG_BUILD_TYPE)
    string(REPLACE "/lib/embree4.lib" "$<$<CONFIG:DEBUG>:/debug>/lib/embree4.lib" contents "${contents}")
endif()
file(WRITE "${config_file}" "${contents}")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()
if(VCPKG_TARGET_IS_OSX OR VCPKG_TARGET_IS_IOS)
    file(REMOVE "${CURRENT_PACKAGES_DIR}/uninstall.command" "${CURRENT_PACKAGES_DIR}/debug/uninstall.command")
endif()
file(RENAME "${CURRENT_PACKAGES_DIR}/share/doc" "${CURRENT_PACKAGES_DIR}/share/${PORT}/")

file(COPY "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
