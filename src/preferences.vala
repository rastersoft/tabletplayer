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
		this.read_config();
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
			this.write_config();
		}
		this.mainw.hide();
	}
	
	private void read_config() {
		var data_file = File.new_for_path(Path.build_filename(GLib.Environment.get_variable("HOME"),".tabletplayer.cfg"));
		if (data_file.query_exists()) {
			try {
				var dis = new DataInputStream (data_file.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
					line = line.strip();
					if (line=="") {
						continue;
					}
					var data = line.split(" ");
					if(data[0]=="force_ffmpeg") {
						if(data[1]=="1") {
							this.force_ffmpeg=true;
						} else {
							this.force_ffmpeg=false;
						}
					}
				}
			} catch (Error e) {
			}
		}
	}
	
	private void write_config() {
		var data_file = File.new_for_path(Path.build_filename(GLib.Environment.get_variable("HOME"),".tabletplayer.cfg"));
		if (data_file.query_exists()) {
			data_file.delete();
		}
		var dos = new DataOutputStream (data_file.create (FileCreateFlags.REPLACE_DESTINATION));
		var data = "force_ffmpeg %s\n".printf(this.force_ffmpeg ? "1" : "0");
		dos.put_string(data);
	}
}