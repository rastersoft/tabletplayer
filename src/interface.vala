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

struct file_info {
	string name;
	GLib.ThemedIcon icon;
	bool isdir;
}

public class UserInterface : GLib.Object {
 
	private Gtk.Builder builder;
	private Gtk.Dialog filer;
	private Gtk.ListStore path_model;
	private Gtk.IconView icon_view;
	private Gtk.ScrolledWindow scroll;
	private Gtk.Label labelpath;
	
	private string? file_selected;
	private string current_path;
 
	private Gee.Map<uint, Gdk.Pixbuf ?>icon_cache;
	private Gee.List<file_info ?> filelist;
	
	private preferences prefs;
 
 	public UserInterface(preferences prefs) {
 	
 		this.prefs=prefs;
 		this.icon_cache = new Gee.HashMap<uint, Gdk.Pixbuf?>();
 		this.builder = new Builder();
		this.builder.add_from_file(Path.build_filename(Constants.PKGDATADIR,"filechooser.ui"));
		this.labelpath = (Gtk.Label)this.builder.get_object("path");
		this.filer = (Gtk.Dialog)this.builder.get_object("filer_dialog");
		this.icon_view = (Gtk.IconView)this.builder.get_object("iconview1");
		this.icon_view.button_release_event.connect(this.on_click);
		this.path_model = (Gtk.ListStore)this.builder.get_object("liststore1");
		this.scroll = (Gtk.ScrolledWindow)this.builder.get_object("scrolledwindow1");
		this.icon_view.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
		this.icon_view.set_pixbuf_column(0);
		this.icon_view.set_text_column(1);
		this.file_selected = null;
		this.current_path=Environment.get_home_dir();
		var button_up = (Gtk.Button) this.builder.get_object("goup");
		button_up.clicked.connect(this.go_up);
	}

	private void go_up() {
		var list_folders = this.current_path.split("/");
		var len = list_folders.length;
		this.current_path="/";
		len--;
		if (len>0) {
			for(var i=0;i<len;i++) {
				this.current_path=Path.build_filename(this.current_path,list_folders[i]);
			}
		}
		this.refresh_files();
	}

	private void set_scroll_top() {
		this.scroll.hadjustment.value=this.scroll.hadjustment.lower;
		this.scroll.vadjustment.value=this.scroll.vadjustment.lower;
	}

	public bool on_click() {

		TreeIter iter;
		string? name=null;
		bool isdir=false;
		
		var model = this.icon_view.model;
		
		GLib.Value path;
		GLib.Value isfolder;

		foreach (var v in this.icon_view.get_selected_items()) {
			model.get_iter(out iter,v);
			model.get_value(iter,2,out isfolder);
			model.get_value(iter,1,out path);
			isdir = isfolder.get_boolean();
			name = path.get_string();
		}
		if (name==null) {
			this.file_selected=null;
			return false;
		}

		if (isdir) {
			this.current_path=Path.build_filename(this.current_path,name);
			this.refresh_files();
			this.set_scroll_top();
			this.icon_view.has_focus=true;
		} else {
			this.file_selected=Path.build_filename(this.current_path,name);
			this.filer.response(1);
		}

		return true;
	}

	private static int mysort_files_byname(file_info? a, file_info? b) {
		if (a.isdir != b.isdir) {
			if (a.isdir) {
				return -1;
			} else {
				return 1;
			}
		}
		if (a.name > b.name) {
			return 1;
		} else {
			return -1;
		}
	}

 	private void refresh_files() {
 
		TreeIter iter;
		Gdk.Pixbuf pbuf_file=this.icon_view.render_icon(Stock.FILE,IconSize.DIALOG,"");
		Gdk.Pixbuf pbuf_folder=this.icon_view.render_icon(Stock.DIRECTORY,IconSize.DIALOG,"");
		Gdk.Pixbuf pbuf=null;
		Gdk.Pixbuf pbuf2=null;
		FileInfo info_file;
		FileType typeinfo;
		bool isdir;
		var movie_info = new MovieInfo(current_path);

		this.labelpath.set_text(current_path);

 		var directory = File.new_for_path(current_path);
		var listfile = directory.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_ICON , FileQueryInfoFlags.NOFOLLOW_SYMLINKS , null);
		var theme = Gtk.IconTheme.get_default();

		this.path_model.clear();
		this.filelist = new Gee.ArrayList<file_info ?>();
		while ((info_file = listfile.next_file(null)) != null) {
			var name = info_file.get_name().dup();
			if (name[0]=='.') {
				continue;
			}
			var element = file_info();
			element.name = name;
			element.icon = (GLib.ThemedIcon)info_file.get_icon();
			if (info_file.get_file_type()==FileType.DIRECTORY) {
				element.isdir=true;
			} else {
				element.isdir=false;
			}
			this.filelist.add(element);
		}
		this.filelist.sort(UserInterface.mysort_files_byname);
		foreach(var file in this.filelist) {	
			var icon_hash=file.icon.hash();
			if ((this.icon_cache.has_key(icon_hash))) {
				pbuf = this.icon_cache.get(icon_hash);
			} else {
				try {
					var tmp1=theme.lookup_by_gicon(file.icon,48,0);
					if (tmp1!=null) {
						pbuf = tmp1.load_icon();
					} else {
						pbuf=null;
					}
				} catch {
					pbuf=null;
				}

				if (pbuf==null) {
					if (file.isdir) {
						pbuf = this.icon_view.render_icon(Stock.FILE,IconSize.DIALOG,"");
					} else {
						pbuf = this.icon_view.render_icon(Stock.DIRECTORY,IconSize.DIALOG,"");
					}
				}
				this.icon_cache.set(icon_hash,pbuf);
			}

			int64 duration;
			int64 last_position;
			if (movie_info.get_data(Path.build_filename(this.current_path,file.name), out duration, out last_position)) {
				var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, pbuf.width, pbuf.height);
				var cairo_ctx = new Cairo.Context(surface); 
				Gdk.cairo_set_source_pixbuf(cairo_ctx,pbuf,0,0);
				cairo_ctx.paint();
				cairo_ctx.set_source_rgba(0,1,0,1);
				cairo_ctx.set_line_width(4.0);
				cairo_ctx.move_to(2,0);
				cairo_ctx.line_to(2,pbuf.height);
				cairo_ctx.stroke();
				cairo_ctx.set_source_rgba(1,0,0,1);
				if (duration>0) {
					var percent = (((int64)pbuf.height)*last_position)/(duration);
					cairo_ctx.move_to(2,percent);
					cairo_ctx.line_to(2,pbuf.height);
					cairo_ctx.stroke();
				}
				pbuf2 = Gdk.pixbuf_get_from_surface(surface,0,0,pbuf.width,pbuf.height);
			} else {
				pbuf2 = pbuf;
			}

			this.path_model.append (out iter);
			this.path_model.set (iter,0,pbuf2);
			this.path_model.set (iter,1,file.name);
			this.path_model.set (iter,2,file.isdir);
		}
 	}
 
	public string ?run() {

		this.file_selected=null;
		this.refresh_files();
		int retval=10;
		do {
			retval=this.filer.run();
			if (retval==11) { // preferences
				this.filer.hide();
				this.prefs.configure();
				retval=10;
				this.filer.show();
			}
		} while (retval==10);
		this.filer.hide();
		return (file_selected);
	}
 
}
