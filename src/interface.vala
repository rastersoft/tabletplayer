/* Tablet Video Player
 * A Video player oriented to tablet devices
 *
 * (C)2013 Raster Software Vigo (Sergio Costas)
 *
 * This code is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>. */
 
using Gtk;
using GLib;

public class UserInterface : Gtk.Window {
 
	private Gtk.Builder builder;
	private Gtk.Dialog filer;
	private Gtk.ListStore path_model;
	private Gtk.IconView icon_view;
	
	private string? file_selected;
 
 	public UserInterface() {
 	
 		this.builder = new Builder();
		this.builder.add_from_file(Path.build_filename(Constants.PKGDATADIR,"filechooser.ui"));
		this.filer=(Gtk.Dialog)this.builder.get_object("filer_dialog");
		this.icon_view=(Gtk.IconView)this.builder.get_object("iconview1");
		this.icon_view.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
		this.file_selected=null;
 	}
 
	public string ?run() {
		this.filer.show_all();
		var retval=this.filer.run();
		this.filer.hide();
		if (retval!=2) {
			return null;
		}

		string path;
		if(this.filer.get_current_folder()!=null) {
			path=GLib.Path.build_path(this.filer.get_current_folder(),this.filer.get_filename());
		} else {
			path=this.filer.get_filename();
		}
		return (path);
	}
 
}
