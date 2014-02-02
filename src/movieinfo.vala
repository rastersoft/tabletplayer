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
using Gee;

private class MovieInfoData : Object {
	public string path;
	public int64 duration;
	public int64 last_position;

	public MovieInfoData(string path, int64 duration, int64 last_position) {
		this.path = path;
		this.duration = duration;
		this.last_position = last_position;
	}
}

public class MovieInfo : Object {
	
	Gee.Map<string,MovieInfoData ?> durations;
	string current_path;
	
	public MovieInfo(string path) {

		FileInfo info_file;

		this.current_path = path;

		this.durations = new Gee.HashMap<string,MovieInfoData ?>();

		var directory = File.new_for_path(path);
		var listfile = directory.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE , FileQueryInfoFlags.NOFOLLOW_SYMLINKS , null);

		var filelist = new Gee.ArrayList<string>();
		while ((info_file = listfile.next_file(null)) != null) {
			var name = info_file.get_name().dup();
			if (name[0]=='.') {
				continue;
			}
			filelist.add(Path.build_filename(path,name));
		}


		var data_file = File.new_for_path(Path.build_filename(path,".tabletplayer.data"));
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
					if (data.length<3) {
						continue;
					}
					var filename = data[0].replace("\\_"," ").replace("\\\\","\\");
					if (filelist.contains(filename)) {
						GLib.stdout.printf("nombre %s\n",filename);
						var element = new MovieInfoData(filename,int64.parse(data[1]),int64.parse(data[2]));
						this.durations.set(filename,element);
					}
				}
			} catch (Error e) {
			}
		}
	}

	public void store_movie_info() {
		var data_file = File.new_for_path(Path.build_filename(this.current_path,".tabletplayer.data"));
		if (data_file.query_exists()) {
			data_file.delete();
		}
		var dos = new DataOutputStream (data_file.create (FileCreateFlags.REPLACE_DESTINATION));
		foreach (var element in this.durations.keys) {
			var data = "%s %lld %lld\n".printf(durations.get(element).path.replace("\\","\\\\").replace(" ","\\_"),durations.get(element).duration,durations.get(element).last_position);
			dos.put_string(data);
		}
	}

	public void set_movie_data(string path, int64 duration, int64 last_position) {
		if (this.durations.has_key(path)) {
			this.durations.unset(path,null);
		}
		var path2 = path;
		var element = new MovieInfoData(path2,duration,last_position);
		this.durations.set(path,element);
		this.store_movie_info();
	}

	public bool get_movie_data(string path, out int64 duration, out int64 last_position) {
		GLib.stdout.printf("pido nombre %s\n",path);
		duration = -1;
		last_position = -1;
		if (this.durations.has_key(path)==false) {
			return false;
		}
		var element = this.durations.get(path);
		duration = element.duration;
		last_position = element.last_position;
		return true;
	}
}