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
using Gdk;
using GLib;
using Gee;

public class preferences:Object {
	
	public bool force_ffmpeg=false;
	
	private Gtk.Builder builder;
	private Gtk.Dialog mainw;
	private Gtk.ToggleButton force_ffmpeg_b;
	
	public preferences() {
		this.builder = new Builder();
		this.builder.add_from_file(Path.build_filename(Constants.PKGDATADIR,"settings.ui"));
		this.mainw=(Gtk.Dialog)this.builder.get_object("settings");
		this.force_ffmpeg_b=(Gtk.ToggleButton)this.builder.get_object("force_ffmpeg");
	}
	
	public void configure() {
		this.force_ffmpeg_b.set_active(this.force_ffmpeg);
		this.mainw.show();
		var retval=this.mainw.run();
		if (retval==2) {
			this.force_ffmpeg=this.force_ffmpeg_b.get_active();
		}
		this.mainw.hide();
	}
}