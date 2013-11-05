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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.	If not, see <http://www.gnu.org/licenses/>. */

using GLib;
using Gtk;
using Gdk;
using Posix;

public class VideoPlayer : Gtk.Window {

	private Gtk.DrawingArea drawing_area;
	private ulong xid;
	private Gtk.Button play_button;
	private Gtk.Button pause_button;
	private Gtk.Label time_text;
	private Gtk.Box controlbox;

	private uint timer;
	private string movie;
	private GLib.Pid pid;
	private int stdinput;
	private int stdoutput;
	private int stderror;
	
	IOChannel io_read;
	IOChannel io_write;
	
	private int64 length;
	private int64 pos;
	private bool paused;
	
	private int timer_show;
	private int timer_basetime;
	private Gtk.Builder builder;
	
	public bool timer_func() {
		size_t v;
		this.io_write.write_chars((char[])"get_time_length\n".data,out v);
		this.io_write.write_chars((char[])"get_time_pos\n".data,out v);
		this.io_write.write_chars((char[])"get_property pause\n".data,out v);
		this.io_write.flush();
		
		if (this.paused) {
			this.timer_show=timer_basetime;
		}

		if (this.timer_show!=0) {
			this.timer_show--;
			if (this.timer_show!=0) {
				this.controlbox.show();
			} else {
				this.controlbox.hide();
			}
		}
		
		return(true);
	}

	public VideoPlayer (string video) {
		this.movie=video;
		this.xid=0;
		this.length=0;
		this.pos=0;
		create_widgets ();
		this.has_resize_grip=false;
		this.show_all();
		this.timer_basetime=10;
		this.timer_show=this.timer_basetime;
		this.paused=false;
		this.timer=GLib.Timeout.add(500,this.timer_func);
	}

	private void create_widgets () {

		// Player section
		
		string[] obj={};
		
		obj+="container";
		this.builder = new Builder();
		this.builder.add_objects_from_file(Path.build_filename(Constants.PKGDATADIR,"interface.ui"),obj);
		
		var playerbox = (Gtk.Box) this.builder.get_object("container");
		this.controlbox = (Gtk.Box) this.builder.get_object("box1");
		this.drawing_area = (Gtk.DrawingArea) this.builder.get_object("video_area");
		this.drawing_area.realize.connect(on_realize);
		this.drawing_area.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
		this.drawing_area.button_press_event.connect(this.on_click);
		this.time_text=(Gtk.Label) this.builder.get_object("timer");
		this.play_button=(Gtk.Button) this.builder.get_object("play");
		play_button.clicked.connect (on_play);
		this.pause_button=(Gtk.Button) this.builder.get_object("pause");
		pause_button.clicked.connect (on_play);
		var stop_button = (Gtk.Button) this.builder.get_object("stop");
		stop_button.clicked.connect (on_stop);
		var avanti =  (Gtk.Button) this.builder.get_object("fast");
		avanti.clicked.connect (on_forward);
		var rewind =  (Gtk.Button) this.builder.get_object("rewind");
		rewind.clicked.connect (on_rewind);
		var audio =  (Gtk.Button) this.builder.get_object("lang");
		audio.clicked.connect (on_audio);
		var audio_p =  (Gtk.Button) this.builder.get_object("volume_up");
		audio_p.clicked.connect (on_audio_plus);
		var audio_m =  (Gtk.Button) this.builder.get_object("volume_down");
		audio_m.clicked.connect (on_audio_minus);
		this.add(playerbox);
	}

	private bool gio_in(IOChannel gio, IOCondition condition) {
		IOStatus ret;
		string msg="";
		size_t len;

		if((condition & IOCondition.HUP) == IOCondition.HUP) {
			return false;
		}

		try {
			string out_msg;
			ret = gio.read_line(out out_msg, out len, null);
			msg=out_msg.replace("\n","");
		}
		catch(IOChannelError e) {
		}
		catch(ConvertError e) {
		}
		if(msg.has_prefix("ANS_LENGTH=")) {
			this.length=int64.parse(msg.substring(11));
		} else if(msg.has_prefix("ANS_TIME_POSITION=")) {
			this.pos=int64.parse(msg.substring(18));
		} else if(msg.has_prefix("ANS_pause=")) {
			if(msg.substring(10)=="no") {
				this.pause_button.show();
				this.play_button.hide();
				this.paused=false;
			} else {
				this.pause_button.hide();
				this.play_button.show();
				this.paused=true;
			}
			int dsec=(int)(this.length%60);
			int dmin=(int)((this.length/60)%60);
			int dhour=(int)(this.length/3600);
			int psec=(int)(this.pos%60);
			int pmin=(int)((this.pos/60)%60);
			int phour=(int)(this.pos/3600);
			string pos_str="%d:%02d:%02d/%d:%02d:%02d".printf(phour,pmin,psec,dhour,dmin,dsec);
			this.time_text.set_text(pos_str);
		}
		return true;
	}

	private void on_realize() {
		var newcursor=new Gdk.Cursor(Gdk.CursorType.BLANK_CURSOR);
		this.get_window().set_cursor(newcursor);
		this.xid = (ulong)Gdk.X11Window.get_xid(this.drawing_area.get_window());
		string[] argv={};
		argv+="mplayer";
		argv+="-fs";
		argv+="-quiet";
		argv+="-slave";
		argv+="-wid";
		argv+="%u".printf((uint)this.xid);
		argv+="%s".printf(this.movie);
		if (false==GLib.Process.spawn_async_with_pipes(null,argv,null,GLib.SpawnFlags.SEARCH_PATH,null,out this.pid, out this.stdinput, out this.stdoutput, out this.stderror)) {
			Gtk.main_quit();
		}
		this.io_write = new IOChannel.unix_new(this.stdinput);
		this.io_read = new IOChannel.unix_new(this.stdoutput);
		if(!(io_read.add_watch(IOCondition.IN | IOCondition.HUP, gio_in) != 0)) {
			print("Cannot add watch on IOChannel!\n");
			return;
		}
	}

	public void on_play () {
		size_t v;
		GLib.stdout.printf("Pausa\n");
		this.io_write.write_chars((char[])"pause\n".data,out v);
		this.io_write.flush();
		this.timer_show=this.timer_basetime;
	}

	public void on_stop () {
		GLib.Source.remove(this.timer);
		size_t v;
		this.io_write.write_chars((char[])"quit 0\n".data,out v);
		Gtk.main_quit();
	}

	public void on_forward() {
		size_t v;
		this.io_write.write_chars((char[])"seek +15 0\n".data,out v);
		this.io_write.flush();
		this.timer_show=this.timer_basetime;
	}

	public void on_rewind() {
		size_t v;
		this.io_write.write_chars((char[])"seek -15 0\n".data,out v);
		this.io_write.flush();
		this.timer_show=this.timer_basetime;
	}
	public void on_audio() {
		size_t v;
		this.io_write.write_chars((char[])"switch_audio\n".data,out v);
		this.io_write.flush();
		this.timer_show=this.timer_basetime;
	}
	
	public void on_audio_plus() {
		size_t v;
		this.io_write.write_chars((char[])"volume 47\n".data,out v);
		this.io_write.flush();
		this.timer_show=this.timer_basetime;
	}
	
	public void on_audio_minus() {
		size_t v;
		this.io_write.write_chars((char[])"volume -47\n".data,out v);
		this.io_write.flush();
		this.timer_show=this.timer_basetime;
	}
	
	private bool on_click(Gdk.EventButton event) {

		if (this.timer_show==0) {
			this.timer_show=this.timer_basetime;
			this.controlbox.show();
		} else {
			this.timer_show=0;
			this.controlbox.hide();
		}
		return true;
	}
}

