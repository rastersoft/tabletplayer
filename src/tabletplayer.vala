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
 
using GLib;
using Gtk;

// project version=0.2

int main(string[] args) {

	Gtk.init (ref args);

	VideoPlayer player;
	UserInterface iface=new UserInterface();

	do {
		var retval=iface.run();
		if (retval==null) {
			break;
		} else {
			player = new VideoPlayer (retval);
			player.destroy.connect( (widget)=> {
				player.on_stop();
			});
			Gtk.main ();
			player.destroy();
			player=null;
		}
	} while(true);

	return 0;
}
