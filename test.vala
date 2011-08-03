/*
    Compile:
    valac --pkg=libxml-2.0 --pkg=gdk-pixbuf-2.0  test.vala -X "-O3" -X "--fast-math" --thread

*/
using GLib;
using Gdk;
using Xml;
Gdk.Pixbuf pb_ori=null;

namespace DNA
{
    namespace Threada
    {
        public GLib.AsyncQueue<DNA.Strain> input = null;
        public GLib.AsyncQueue<DNA.Strain> output= null;

        public void * thread_func()
        {
            while(true)
            {
                DNA.Strain a = input.pop();
                while(!a.Mutate());
                DNA.Tool.Fitness(a,pb_ori);
                output.push((owned)a);
            }
        }

        public void create_threads()
        {
            try{
                Thread.create<void*> (thread_func, true);
                Thread.create<void*> (thread_func, true);
                Thread.create<void*> (thread_func, true);
                Thread.create<void*> (thread_func, true);
                Thread.create<void*> (thread_func, true);
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
            uint64 diff = 0;
            uint width = pb.width;
            uint height = pb.height;
            uint chan = pb.get_n_channels();
            //pb.get_n_channels();
            uint chan_dst = 3;
            /* Render current dna */
            /* Get pixel data */
            uchar[] pixels_data = new uchar[width*height*chan_dst];
            unowned uchar[] pixels = pb.get_pixels();
            render_strain(pixels_data,width,height, chan_dst,str);

            /* get stride */
            uint pb_stride = pb.get_rowstride();
            uint pb_dst_stride = width*chan_dst;
            /* channels */
            int64 r,b,g;

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
            str.fitness = diff;
        }
    }
}


int main ( string[] argv)
{
    uint iter = 0;
    uint generation =0;
    uint old_generation = 0;
    uint64 old_fitness = uint64.MAX;
    DNA.Threada.input = new AsyncQueue<DNA.Strain>();
    DNA.Threada.output = new AsyncQueue<DNA.Strain>();

    /* open input image */
    try
    {
        pb_ori = new Gdk.Pixbuf.from_file(argv[1]);
    }
    catch(GLib.Error error)
    {
        GLib.error("Failed to load input image: %s\n", error.message);
    }
    {
        unowned uchar[] data = pb_ori.get_pixels();
        write_ppm("ori.ppm", data, 200,200,4);
    }
    DNA.Threada.create_threads();

    GLib.Timer timer = new GLib.Timer();
    DNA.Tool.rand = new GLib.Rand();
    DNA.Strain? str = null;
    if(argv.length == 3) {
        str = new DNA.Strain.from_file(argv[argv.length-1]);
        old_fitness = str.fitness;

        uchar[800*800*3] pixels = new uchar[800*800*3];
        render_strain(pixels, 800, 800, 3,str);
        write_ppm("xmlinput.ppm", pixels, 800,800,3);

    }else{
        str = new DNA.Strain();
    }
    int length  = 0;
    stdout.printf("feed: %u\n", iter);
    while(length <2)
    {
        var str2 = new DNA.Strain.Clone(str);
        {
            DNA.Threada.input.push((owned)str2);
            length++;
            generation++;
        }

    }
    length = 0;

    do
    {
        DNA.Strain a = DNA.Threada.output.pop();
        if(a.fitness < old_fitness)
        {
            old_fitness = a.fitness;
            /* Mark current one as best */
            str = (owned)a;
            iter++;
            if(iter % 100 == 0)
            {
                uchar[800*800*3] pixels = new uchar[800*800*3];
                render_strain(pixels, 800, 800, 3,str);
                str.store_xml("test%08lu.xml".printf(iter));

                write_ppm("test%08lu.ppm".printf(iter), pixels, 800,800,3);
                GLib.debug("Write file: test%08lu.png".printf(iter));
                GLib.debug("Write res: %llu fittn: %llu\n", generation, old_fitness);
                GLib.debug("Time: %f, fpsL: %f", timer.elapsed(), (generation-old_generation)/timer.elapsed());
                str.print();
                old_generation = generation;
                timer.reset();

            }
        }
        var str2 = new DNA.Strain.Clone(str);
        {
            DNA.Threada.input.push((owned)str2);
            length++;
            generation++;
        }
    }while(old_fitness > 1000);
    str.print();
    pb_ori = null;
    return 0;
}


void write_ppm(string filename, uchar[] pixels, uint width, uint height, uint nchan)
{
    GLib.FileStream fs = GLib.FileStream.open(filename, "w");
    fs.printf("P6\n%u %u %u\n", width, height, 255);
    for(uint i=0; i < height; i++)
    {
        for(uint j=0; j<width*nchan;j+=nchan)
        {
            fs.putc((char)pixels[i*width*nchan+j]);
            fs.putc((char)pixels[i*width*nchan+j+1]);
            fs.putc((char)pixels[i*width*nchan+j+2]);
        }
    }
    fs = null;
}

void render_strain(uchar[] pixels, uint width, uint height, uint nchan, DNA.Strain strain)
{
    uint stride = width*nchan;
    /* Clear */
    GLib.Memory.set(pixels, 0, stride*height);
    /* itterate over each polygon */
    foreach(unowned DNA.Polygon pol in strain.polygons)
    {
        unowned DNA.Brush b  = pol.GetBrush();
        unowned DNA.Point p0 = pol.points.nth_data(0);
        unowned DNA.Point p1 = pol.points.nth_data(1);
        unowned DNA.Point p2 = pol.points.nth_data(2);

        float v0x = p2.x - p0.x;
        float v0y = p2.y - p0.y;
        float dot00 = v0x*v0x + v0y*v0y;

        float v1x = p1.x - p0.x;
        float v1y = p1.y - p0.y;

        float dot01 = v0x*v1x + v0y*v1y;
        float dot11 = v1x*v1x + v1y*v1y;

        float invdenom = 1.0f / (float)(dot00*dot11 - dot01*dot01);
        uint y_max = (uint)(pol.bottom.y*height);
        uint x_max = (uint)(pol.bottom.x*stride);


        for(uint i=(uint)(pol.top.y*height); i < y_max; i++)
        {
            uint uy = i*stride;
            // Make sure j is multiple of 4.
            for(uint j=nchan*((uint)(pol.top.x*width)); j<x_max;j+=nchan)
            {
                float v2x =  j/(float)(stride) - p0.x;
                float v2y =  i/(float)(height) - p0.y;
                float dot02 = v0x*v2x + v0y*v2y;
                float dot12 = v1x*v2x + v1y*v2y;

                float u = (dot11*dot02 - dot01*dot12) * invdenom;
                if( u > 0 )
                {
                    float v = (dot00*dot12 - dot01*dot02) * invdenom;
                    if( v > 0 )
                    {
                        if(u + v < 1)
                        {
                            uint index = uy+j;
                            pixels[index] =   (uchar)((b.r*b.a) +(1-b.a)*(pixels[index]  ));
                            pixels[index+1] = (uchar)((b.g*b.a) +(1-b.a)*(pixels[index+1]));
                            pixels[index+2] = (uchar)((b.b*b.a) +(1-b.a)*(pixels[index+2]));
                        }
                    }
                }
            }
        }
    }
}
