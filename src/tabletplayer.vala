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
    
	public VideoPlayer () {
        create_widgets ();
        setup_gst_pipeline("/home/raster/Escritorio/mule_vistos/Apolo.13.(Edicion.Especial).(Spanish).(DVD-Rip).(XviD-AC3-5.1).[HispaShare.Com].(by.SDG).(sdg-es.com).avi");
    }

    private void create_widgets () {
        var vbox = new Box (Orientation.VERTICAL, 0);
        this.drawing_area = new DrawingArea ();
        this.drawing_area.realize.connect(on_realize);
        vbox.pack_start (this.drawing_area, true, true, 0);

        var play_button = new Button.from_stock (Stock.MEDIA_PLAY);
        play_button.clicked.connect (on_play);
        var stop_button = new Button.from_stock (Stock.MEDIA_STOP);
        stop_button.clicked.connect (on_stop);
        var quit_button = new Button.from_stock (Stock.QUIT);
        quit_button.clicked.connect (Gtk.main_quit);

        var bb = new ButtonBox (Orientation.HORIZONTAL);
        bb.add (play_button);
        bb.add (stop_button);
        bb.add (quit_button);
        vbox.pack_start (bb, false, true, 0);

        add (vbox);
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
    }

    private void setup_gst_pipeline (string location) {
        this.pipeline = new Pipeline ("mypipeline");
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

    private void on_play () {
        var xoverlay = this.videosink as Gst.XOverlay;
        xoverlay.set_xwindow_id (this.xid);
        this.pipeline.set_state (State.PLAYING);
    }

    private void on_stop () {
        this.pipeline.set_state (State.READY);
    }    
}

int main(string[] args) {

	Gst.init (ref args);
    Gtk.init (ref args);

    var player = new VideoPlayer ();
    player.show_all ();

    Gtk.main ();

    return 0;


}
