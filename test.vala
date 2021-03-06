/*
    Compile:
    valac --pkg=libxml-2.0 --pkg=gdk-pixbuf-2.0  test.vala -X "-O3" -X "--fast-math" --thread

*/
using GLib;
using Gdk;
Gdk.Pixbuf pb_ori=null;

uint number_threads = 6;

namespace DNA
{
    public class Worker
    {
	    public GLib.AsyncQueue<DNA.Strain> input = null;
	    public GLib.AsyncQueue<DNA.Strain> output= null;

	    public Worker()
	    {
    		input = new AsyncQueue<DNA.Strain>();
		    output = new AsyncQueue<DNA.Strain>();
			create_threads();

		}
        public void * thread_func()
        {
            while(true)
            {
                DNA.Strain a = input.pop();
                while(!a.Mutate());
                DNA.Tool.Fitness(a, pb_ori);
                output.push((owned)a);
            }
        }

        public void create_threads()
		{
				try{
						for(uint i=0; i<number_threads;i++)
						{
								Thread.create<void*> (thread_func, true);
						}
				}catch(ThreadError e) {
						GLib.error("Failed to create thread: %s", e.message);
				}
		}

    }
    namespace Tool
    {
        public GLib.Rand rand;

        public bool Mutate(int pos)
        {
            return (DNA.Tool.rand.int_range(0, pos) == 0);
        }

        public void Fitness(Strain str, Gdk.Pixbuf pb)
        {
            double diff = 0;
            uint width = pb.width;
            uint height = pb.height;
            uint chan = pb.get_n_channels();
            //pb.get_n_channels();
            uint chan_dst = 3;
            /* Render current dna */
            /* Get pixel data */
            uchar[] pixels_data = new uchar[width*height*chan_dst];
            unowned uchar[] pixels = pb.get_pixels();
            Render(str,pixels_data,width,height, chan_dst);

            /* get stride */
            uint pb_stride = pb.get_rowstride();
            uint pb_dst_stride = width*chan_dst;
            /* channels */
            int r,b,g;

            for(int h = 0; h<height;h++)
            {
                uint hpos_src = h*pb_stride;
                uint hpos_dst = h*pb_dst_stride;
                for(uint x = 0; x < width; x++)
                {
                    uint pos_src = hpos_src+x*chan;
                    uint pos_dst = hpos_dst+x*chan_dst;
                    // r
                    r = ((int)pixels[pos_src+0]-(int)pixels_data[pos_dst+0]);
                    //g
                    g = ((int)pixels[pos_src+1]-(int)pixels_data[pos_dst+1]);
                    //b
                    b = ((int)pixels[pos_src+2]-(int)pixels_data[pos_dst+2]);
                    diff += g*g;
                    diff += r*r;
                    diff += b*b;
                }
            }
            str.fitness = diff/(3*width*height*255.0*255.0);
        }
    }
}

string input_file = null;
int population_size = 16;
int output_width=0;
int output_height=0;
string initial_xml = null;
string render_xml = null;
bool output_png = false;
const GLib.OptionEntry[] entries = {
		{"input",   'i', 0, GLib.OptionArg.FILENAME, ref input_file, "Input file", null},
		{"threads", 'j', 0, GLib.OptionArg.INT, ref number_threads, "Number of CPU threads to run", null},
		{"population",   'p', 0, GLib.OptionArg.INT, ref population_size, "Size of the popution (default 16)", null},
		{"initial",   'n', 0, GLib.OptionArg.FILENAME, ref initial_xml, "Initial file", null},
		{"render",   'r', 0, GLib.OptionArg.FILENAME, ref render_xml, "Render file", null},
		{"width", 	'w' , 0, GLib.OptionArg.INT, ref output_width, "Output width", null},
		{"height", 	'h' , 0, GLib.OptionArg.INT, ref output_height, "Output height", null},
		{"output-png", 	0 , 0, GLib.OptionArg.NONE, ref output_png, "Output png instead of svg", null},
		{null}
};

int main ( string[] argv)
{
    uint iter = 0;
    uint generation =0;
    uint old_generation = 0;
    double old_fitness = 2;

	GLib.OptionContext og = new GLib.OptionContext("Evo");
	og.add_main_entries(entries,null);
	try{
		og.parse(ref argv);
	}catch (Error e) {
		GLib.error("Failed to parse command line options: %s\n", e.message);
	}

    if(render_xml != null) {
        if(initial_xml == null){
            GLib.error("initial_file == null: You need to specify an initial file");
        }
		
		var str = new DNA.Strain.from_file(initial_xml);
		if(output_png) {
			DNA.RenderPNG(render_xml, str, output_width, output_height);
		}else{
			DNA.RenderSVG(render_xml, str, output_width, output_height);
		}
		return 0;
    }

	if(input_file == null) {
		GLib.error("input_file == null: You need to specify an input file");
	}

    /* open input image */
    try
    {
        pb_ori = new Gdk.Pixbuf.from_file(input_file);
    }
    catch(GLib.Error error)
    {
        GLib.error("Failed to load input image: %s\n", error.message);
    }

	if(output_height == 0 || output_width == 0) {
		output_height = pb_ori.height;
		output_width = pb_ori.width;
	}
    /* Create threads */
	DNA.Worker w  = new DNA.Worker();


    GLib.Timer timer = new GLib.Timer();
    DNA.Tool.rand = new GLib.Rand();
    DNA.Strain? str = null;
    /* Load initial file */
    if(initial_xml != null) {
        str = new DNA.Strain.from_file(initial_xml);
        old_fitness = str.fitness;
        iter = str.generation;
    }else{
        str = new DNA.Strain();
    }

    int length  = 0;
    for(int i=0; i < population_size; i++)
    {
        var str2 = new DNA.Strain.Clone(str);
        w.input.push((owned)str2);
        generation++;
    }

    do
    {
        DNA.Strain a = w.output.pop();
        if(a.fitness < old_fitness)
        {
            old_fitness = a.fitness;
            /* Mark current one as best */
            str = (owned)a;
            iter++;
            if(iter % 100 == 0)
            {
            	str.store_xml("test%08lu.xml".printf(iter), iter);
				DNA.RenderSVG("test%08u.svg".printf(iter), str, output_width, output_height);
				//PPM.Write(str, "test%08lu.ppm".printf(iter),output_width,output_height);
                GLib.debug("Write file: test%08lu.png".printf(iter));
                GLib.debug("Write res: %llu fittn: %f\n", generation, old_fitness);
                GLib.debug("Time: %f, fpsL: %f", timer.elapsed(), (generation-old_generation)/timer.elapsed());
                str.print();
                old_generation = generation;
                timer.reset();

            }
        }
        var str2 = new DNA.Strain.Clone(str);
        {
            w.input.push((owned)str2);
            length++;
            generation++;
        }
    }while(old_fitness > 0.0001);

    /* We are done */
	str.store_xml("test%08lu.xml".printf(iter),iter);
	DNA.RenderSVG("test%08u.svg".printf(iter), str, output_width, output_height);

    str.print();

    pb_ori = null;
    return 0;
}
