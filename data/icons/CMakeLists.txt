### CMakeLists automatically created with AutoVala
### Do not edit

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/tabletplayer.svg DESTINATION share/icons/hicolor/scalable/apps/)
IF( NOT (${ICON_UPDATE} STREQUAL "OFF" ))
	install (CODE "execute_process ( COMMAND /usr/bin/gtk-update-icon-cache-3.0 -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor )" )
ENDIF()
