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
using Gst;
using Gdk;

public class VideoPlayer : Gtk.Window {

	private DrawingArea drawing_area;
	private Pipeline pipeline;
	private Element filesrc;
	private Element decoder;
	private Element videosink;
	private Element audiosink;
	private ulong xid;
	private Box playerbox;
	private Button play_button;
	private Button pause_button;
	private int64 duration;
	private int64 position;
	private Gst.Bus bus;
	private Gtk.Label time_text;

	private bool is_playing;
	private uint timer;
	
	private bool is_initializated;

	public bool timer_func() {
		if (this.set_xv()) {
			return(true);
		}
		Gst.Format fmt = Gst.Format.TIME;
		this.pipeline.query_duration(ref fmt,out this.duration);
		this.pipeline.query_position(ref fmt,out this.position);
		int dur2=(int)(duration/Gst.SECOND);
		int pos2=(int)(position/Gst.SECOND);
		int dsec=dur2%60;
		int dmin=(dur2/60)%60;
		int dhour=dur2/3600;
		int psec=pos2%60;
		int pmin=(pos2/60)%60;
		int phour=pos2/3600;
		string pos_str="%d:%02d:%02d/%d:%02d:%02d".printf(phour,pmin,psec,dhour,dmin,dsec);
		this.time_text.set_text(pos_str);
		return(true);
	}

	private bool set_xv() {
		if ((this.xid!=0)&&(this.is_initializated==false)) {
			this.is_initializated=true;
			var xoverlay = this.videosink as Gst.XOverlay;
			xoverlay.set_xwindow_id(this.xid);
			this.is_playing=false;
			this.on_play();
			return true;
		}
		return false;
	}

	public VideoPlayer (string video) {
		this.xid=0;
		this.is_initializated=false;
		create_widgets ();
		setup_gst_pipeline(video);
		this.timer=GLib.Timeout.add(1000,this.timer_func);
	}

	private void create_widgets () {

		// Player section
		var playerbox = new Box (Orientation.VERTICAL, 0);
		this.drawing_area = new DrawingArea ();
		this.drawing_area.realize.connect(on_realize);
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

		var bb = new ButtonBox (Orientation.HORIZONTAL);
		bb.set_layout(Gtk.ButtonBoxStyle.START);
		bb.add (rewind);
		bb.add (play_button);
		bb.add (pause_button);
		bb.add (stop_button);
		bb.add (avanti);
		var controlbox=new Box (Orientation.HORIZONTAL,0);
		playerbox.pack_start (controlbox, false, true, 0);
		controlbox.pack_start (bb, true, true, 0);
		this.time_text=new Label("");
		this.time_text.set_justify(Gtk.Justification.CENTER);
		controlbox.pack_start (this.time_text, false, true, 10);
		this.add(playerbox);
		this.show_all();
	}

	public void on_forward() {
		if (is_playing==false) {
			return;
		}
		int64 pos=-1;
		Gst.Format fmt = Gst.Format.TIME;
		if (this.pipeline.query_position(ref fmt,out pos)) {
			pos+=20*Gst.SECOND;
			if (pos<this.duration) {
				this.pipeline.seek_simple(Gst.Format.TIME,Gst.SeekFlags.FLUSH|Gst.SeekFlags.KEY_UNIT,pos);
			}
		}
	}

	public void on_rewind() {
		if (is_playing==false) {
			return;
		}
		int64 pos=-1;
		Gst.Format fmt;
		fmt = Gst.Format.TIME;
		if (this.pipeline.query_position(ref fmt,out pos)) {
			pos-=20*Gst.SECOND;
			if (pos<0) {
				pos=0;
			}
			this.pipeline.seek_simple(Gst.Format.TIME,Gst.SeekFlags.FLUSH|Gst.SeekFlags.KEY_UNIT,pos);
		}
	}

	public void OnDynamicPad(Gst.Element element,Gst.Pad new_pad) {
		var new_pad_caps = new_pad.get_caps();
		weak Gst.Structure new_pad_struct = new_pad_caps.get_structure (0);
		string new_pad_type = new_pad_struct.get_name ();
		if(new_pad_type.has_prefix("video/")) {
			Pad opad=this.videosink.get_static_pad("sink");
			new_pad.link(opad);
		}
		if(new_pad_type.has_prefix("audio/")) {
			Pad opad=this.audiosink.get_static_pad("sink");
			new_pad.link(opad);
		}
		this.set_iface();
	}

	private void set_iface() {
		if(this.is_playing) {
			this.play_button.hide();
			this.pause_button.show();
		} else {
			this.play_button.show();
			this.pause_button.hide();
		}
	}

	private void bus_msg(Gst.Message msg) {
		GLib.stdout.printf("Mensaje\n");
	}

	private void bus_msg2(Gst.Message msg) {
		GLib.stdout.printf("Mensaje 2\n");
	}

	private void setup_gst_pipeline (string location) {
		this.pipeline = new Pipeline ("mypipeline");
		this.bus = this.pipeline.get_bus();
		this.bus.message.connect(this.bus_msg);
		this.bus.sync_message.connect(this.bus_msg2);
		this.filesrc = ElementFactory.make ("filesrc", "filesource");
		this.filesrc.set("location",location);
		this.decoder = ElementFactory.make("decodebin","decoder");
		this.decoder.pad_added.connect(OnDynamicPad);
		this.videosink = ElementFactory.make("xvimagesink", "videosink");
		this.videosink.set("force-aspect-ratio",true);
		this.audiosink = ElementFactory.make("autoaudiosink","audiosink");
		this.pipeline.add_many (this.filesrc, this.videosink,this.audiosink,this.decoder);
		this.filesrc.link(this.decoder);
	}

	private void on_realize() {
		this.xid = (ulong)Gdk.X11Window.get_xid(this.drawing_area.get_window());
	}

	public void on_play () {
		if(this.is_playing) {
			this.pipeline.set_state (State.PAUSED);
			this.is_playing=false;
		} else {
			this.pipeline.set_state (State.PLAYING);
			this.is_playing=true;
		}
		this.set_iface();
	}

	public void on_stop () {
		GLib.Source.remove(this.timer);
		this.pipeline.set_state (State.READY);
		this.hide();
		Gtk.main_quit();
	}
}

