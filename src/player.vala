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

	private DrawingArea drawing_area;
	private ulong xid;
	private Button play_button;
	private Button pause_button;
	private Gtk.Label time_text;
	private Box controlbox;

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
	
	private int timer_show;

// switch audio

	public bool timer_func() {
		size_t v;
		this.io_write.write_chars((char[])"get_time_length\n".data,out v);
		this.io_write.write_chars((char[])"get_time_pos\n".data,out v);
		this.io_write.write_chars((char[])"get_property pause\n".data,out v);
		this.io_write.flush();
		
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
		this.show_all();
		timer_show=8;
		this.timer=GLib.Timeout.add(500,this.timer_func);
	}
	
	private bool on_click(Gdk.EventButton event) {

		this.timer_show=8;
		this.controlbox.show();
		return true;
	}

	private void create_widgets () {

		// Player section
		var playerbox = new Box (Orientation.VERTICAL, 0);
		this.drawing_area = new DrawingArea ();
		this.drawing_area.realize.connect(on_realize);
		this.drawing_area.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
		this.drawing_area.button_press_event.connect(this.on_click);
		playerbox.pack_start (this.drawing_area, true, true, 0);

		play_button = new Button.from_stock(Stock.MEDIA_PLAY);
		play_button.clicked.connect (on_play);
		pause_button = new Button.from_stock(Stock.MEDIA_PAUSE);
		pause_button.clicked.connect (on_play);
		var stop_button = new Button.from_stock(Stock.MEDIA_STOP);
		stop_button.clicked.connect (on_stop);
		var avanti = new Button.from_stock(Stock.MEDIA_FORWARD);
		avanti.clicked.connect (on_forward);
		var rewind = new Button.from_stock(Stock.MEDIA_REWIND);
		rewind.clicked.connect (on_rewind);
		var audio = new Button.with_label(_("Audio"));
		audio.clicked.connect (on_audio);

		var bb = new ButtonBox (Orientation.HORIZONTAL);
		bb.set_layout(Gtk.ButtonBoxStyle.START);
		bb.add (rewind);
		bb.add (play_button);
		bb.add (pause_button);
		bb.add (stop_button);
		bb.add (avanti);
		bb.add (audio);
		this.controlbox=new Box (Orientation.HORIZONTAL,0);
		playerbox.pack_start (controlbox, false, true, 0);
		controlbox.pack_start (bb, true, true, 0);
		this.time_text=new Label("");
		this.time_text.set_justify(Gtk.Justification.CENTER);
		controlbox.pack_start (this.time_text, false, true, 10);
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
			} else {
				this.pause_button.hide();
				this.play_button.show();
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
		this.io_write.write_chars((char[])"pause\n".data,out v);
		this.io_write.flush();
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
	}

	public void on_rewind() {
		size_t v;
		this.io_write.write_chars((char[])"seek -15 0\n".data,out v);
		this.io_write.flush();
	}
	public void on_audio() {
		size_t v;
		this.io_write.write_chars((char[])"switch_audio\n".data,out v);
		this.io_write.flush();
	}
}

