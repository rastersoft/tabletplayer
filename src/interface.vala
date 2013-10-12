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
 
	private Gtk.FileChooserDialog filer;
 
 	public UserInterface() {
 		this.filer=new Gtk.FileChooserDialog(_("Select movie"),null, Gtk.FileChooserAction.OPEN,_("_Cancel"),Gtk.ResponseType.CANCEL,_("_Open"),Gtk.ResponseType.ACCEPT);
 	}
 
	public string ?run() {
		this.filer.show_all();
		var retval=this.filer.run();
		this.filer.hide();
		if (retval==Gtk.ResponseType.CANCEL) {
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
