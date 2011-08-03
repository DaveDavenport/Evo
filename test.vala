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


    /* The complete DNA strain */
    public class Strain
    {
        public uint64 fitness = 0;
        /* posibilities */
        private const int mutation_pos_add = 200;
        private const int mutation_pos_remove = 1500;

        private const int initial_polygons = 3;
        public List<DNA.Polygon> polygons;

        /**
         * Strain()
         * Creates a number of initial polygons.
         */
        public Strain()
        {
            for(int j=0; j<initial_polygons;j++)
            {
                AddPolygon(new Polygon());
            }
        }

        /**
         * Make a copy
         */
        public Strain.Clone(Strain s)
        {
            foreach(unowned DNA.Polygon pol in s.polygons)
            {
                AddPolygon(new Polygon.Clone(pol));
            }
            polygons.reverse();
        }

        /**
         * Add a polygon
         */
        public void AddPolygon(Polygon a)
        {
            polygons.prepend(a);
        }

        /**
         * Remove a polygon
         */
        public void RemovePolygon(Polygon a)
        {
            unowned List<Polygon> en = polygons.find(a);
            if(en != null)
            {
                var pol = (owned)en.data;
                polygons.delete_link(en);
                pol = null;
            }
        }

        /**
         * Mutate
         */
        public bool Mutate()
        {
            bool dirt = false;
            /* Mutate Add a polygon */
            if(DNA.Tool.Mutate(mutation_pos_add))
            {
                AddPolygon(new Polygon());
                dirt = true;
            }
            /* Mutate each polygon */
            List<Polygon> remove_list = null;
            foreach(unowned Polygon pol in polygons)
            {
                /* Check if this polygon is removed, otherwise mutate */
                if(DNA.Tool.Mutate(mutation_pos_remove))
                {
                    remove_list.prepend(pol);
                    dirt = true;
                }
                else
                {
                    if(pol.Mutate())
                    {
                        dirt = true;
                    }
                }
            }
            /* Actually remove the polygons */
            foreach(unowned Polygon pol in remove_list)
            {
                RemovePolygon(pol);
            }
            /* set dirty */
            return dirt;
        }
        /**
         * print
         */
        public void print()
        {
            GLib.debug("Polygons: %u", polygons.length());
            uint points=0;
            foreach(unowned Polygon p in polygons)
            {
                points+= p.points.length();
            }
            GLib.debug("Points: %u\n", points);
        }

        public void store_xml(string xml_file)
        {
            Xml.Doc doc = new Xml.Doc(null);
            Xml.Node *root = new Xml.Node(null, "strain");
            Xml.Node *fitn = new Xml.Node(null, "fitness");
            fitn->set_content("%llu".printf(fitness));

            foreach(unowned Polygon p in polygons)
            {
                p.store_xml(root);
            }

            root->add_child(fitn);
            doc.set_root_element(root);
            doc.save_format_file(xml_file,1);
        }
        /**
         * Strain.from_file(string file)
         */
        public Strain.from_file(string xml_file)
        {
            Xml.Doc doc = Xml.Parser.parse_file(xml_file);
            Xml.Node *root = doc.get_root_element();
            for(Xml.Node *iter =  root->children; iter != null; iter = iter->next)
            {
                if(iter->name == "polygon")
                {
                    stdout.printf("add polygon\n");
                    var pol = new Polygon.from_xml(iter);
                    AddPolygon(pol);
                }
                else if (iter->name == "fitness")
                {
                    fitness = int.parse(iter->get_content());
                }
            }
            polygons.reverse();
        }
    }


    public class Polygon
    {
        private const int mutation_pos_add = 700;
        private const int mutation_pos_remove = 1500;
        private const int initial_points = 3;
        public List<DNA.Point> points;
        public DNA.Point top = new DNA.Point();
        public DNA.Point bottom = new DNA.Point();
        private Brush brush;

        public void store_xml(Xml.Node *node)
        {
            Xml.Node *polygon = new Xml.Node(null,"polygon");
            brush.store_xml(polygon);
            foreach(unowned DNA.Point p in points)
            {
                p.store_xml(polygon);
            }
            node->add_child(polygon);
        }

        public Polygon.from_xml(Xml.Node *node)
        {
            for(Xml.Node *iter =  node->children; iter != null; iter = iter->next)
            {
                if(iter->name == "point")
                {
                    stdout.printf("add point\n");
                    DNA.Point point = new DNA.Point.from_xml(iter);
                    AddPoint(point);
                }
                else if (iter->name == "brush")
                {
                    stdout.printf("add brush\n");
                    DNA.Brush b = new DNA.Brush.from_xml(iter);
                    brush = b;
                }
            }
            points.reverse();
            update_bb();
        }

        private void update_bb()
        {
            bool init =true;
            foreach(unowned DNA.Point p in points)
            {
                if(init) {
                    top.x = p.x;
                    top.y = p.y;
                    bottom.x = p.x;
                    bottom.y = p.y;
                    init = false;
                }else{
                     top.x = float.min(top.x,p.x);
                     top.y = float.min(top.y, p.y);
                     bottom.x = float.max(bottom.x,p.x);
                     bottom.y = float.max(bottom.y, p.y);

                }
            }
        }
        /**
         * Constructor
         */
        public Polygon()
        {
            brush = new Brush();
            for(int j=0;j<initial_points;j++)
            {
                AddPoint(new DNA.Point());
            }
            points.reverse();
            update_bb();
        }

        /**
         * Getter for brush
         */
        public unowned Brush GetBrush()
        {
            return brush;
        }

        /**
         * Clone polygon
         */
        public Polygon.Clone(Polygon pol)
        {

            brush = new Brush.Clone(pol.brush);
            foreach (unowned Point p in pol.points)
            {
                AddPoint(new Point.Clone(p));
            }
            top.x = pol.top.x;
            top.y = pol.top.y;
            bottom.x = pol.bottom.x;
            bottom.y = pol.bottom.y;
            points.reverse();
        }

        /**
         * Add a point
         */
        public void AddPoint(Point p)
        {
            points.prepend(p);
        }

        /**
         * Remove a point
         */
        public void RemovePoint(Point p)
        {
            unowned List<Point> en = points.find(p);
            if(en != null)
            {
                var pol = (owned)en.data;
                points.delete_link(en);
                pol = null;
            }
        }
        /**
         * Mutate
         */
        public bool Mutate()
        {
            bool dirt = false;

            if(false && DNA.Tool.Mutate(mutation_pos_add))
            {
                AddPoint(new Point());
                dirt = true;
            }
            List<Point> remove_list = null;
            foreach(unowned DNA.Point P in points)
            {
                if(false && DNA.Tool.Mutate(mutation_pos_remove))
                {
                    remove_list.prepend(P);
                }
                else
                {
                    if(P.Mutate())
                    {
                        dirt = true;
                    }
                }
            }
            foreach(unowned DNA.Point P in remove_list)
            {
                RemovePoint(P);
                dirt = true;
            }
            if(dirt) {
                update_bb();
            }
            if(brush.Mutate())
            {
                dirt = true;
            }

            return dirt;
        }
    }

    /**
     * Point()
     */
    public class Point
    {
        private const int mutation_pos_x = 1500;
        private const int mutation_pos_y = 1500;
 // {get; set; default=0;}
        public float x=0;
 // {get; set; default=0;}
        public float y=0;


        public Point.from_xml(Xml.Node *node)
        {
            for(Xml.Node *iter =  node->children; iter != null; iter = iter->next)
            {
                if(iter->name == "x")
                {
                    x = (float)double.parse(iter->get_content());
                }else if (iter->name == "y")
                {
                    y = (float)double.parse(iter->get_content());
                }
            }
            stdout.printf("%fx%f\n", x, y);
        }

        public void store_xml(Xml.Node *node)
        {
            Xml.Node *point = new Xml.Node(null, "point");
            Xml.Node *xnode = new Xml.Node(null, "x");
            Xml.Node *ynode = new Xml.Node(null, "y");

            xnode->set_content("%f".printf(x));
            ynode->set_content("%f".printf(y));
            point->add_child(xnode);
            point->add_child(ynode);
            node->add_child(point);
        }

        public Point()
        {
            x = (float)DNA.Tool.rand.double_range(0, 1);
            y = (float)DNA.Tool.rand.double_range(0, 1);
        }

        public Point.Clone(Point p)
        {
            x = p.x;
            y = p.y;
        }
        public bool Mutate()
        {
            bool dirt = false;
            if(Tool.Mutate(mutation_pos_x))
            {
                x = (float)DNA.Tool.rand.double_range(0, 1);
                dirt =true;
            }
            if(Tool.Mutate(mutation_pos_y))
            {
                y = (float)DNA.Tool.rand.double_range(0, 1);
                dirt =true;
            }
            return dirt;
        }
    }

    /**
     * Brush()
     */
    public class Brush
    {
        private const int mutation_pos_r = 1200;
        private const int mutation_pos_g = 1200;
        private const int mutation_pos_b = 1200;
        private const int mutation_pos_a = 1200;
        public uint8 r;
        public uint8 g;
        public uint8 b;
        public float a;
        /* construct */
        public Brush()
        {
            r = (uint8)DNA.Tool.rand.int_range(0, 1);
            g = (uint8)DNA.Tool.rand.int_range(0, 255);
            b = (uint8)DNA.Tool.rand.int_range(0, 255);
            a = (float)(float)DNA.Tool.rand.double_range(0, 1);
        }
        /* Clone it */
        public Brush.Clone(Brush brush)
        {
            r = brush.r;
            g = brush.g;
            b = brush.b;
            a = brush.a;
        }

        public Brush.from_xml(Xml.Node *node)
        {
            for(Xml.Node *iter =  node->children; iter != null; iter = iter->next)
            {
                if(iter->name == "red")
                {
                    r = (uint8)int.parse(iter->get_content());
                }
                else if(iter->name == "green")
                {
                    g = (uint8)int.parse(iter->get_content());
                }
                else if(iter->name == "blue")
                {
                    b = (uint8)int.parse(iter->get_content());
                }
                else if(iter->name == "alpha")
                {
                    a = (float)double.parse(iter->get_content());
                }
            }
            stdout.printf("%u %u %u - %f\n", r,g,b,a);
        }

        public bool Mutate()
        {
            bool dirt = false;
            if(DNA.Tool.Mutate(mutation_pos_r))
            {
                r = (uint8)DNA.Tool.rand.int_range(0, 255);
                dirt = true;
            }
            if(DNA.Tool.Mutate(mutation_pos_g))
            {
                g = (uint8)DNA.Tool.rand.int_range(0, 255);
                dirt = true;
            }
            if(DNA.Tool.Mutate(mutation_pos_b))
            {
                b = (uint8)DNA.Tool.rand.int_range(0, 255);
                dirt = true;
            }
            if(DNA.Tool.Mutate(mutation_pos_a))
            {
                a = (float)(float)DNA.Tool.rand.double_range(0, 1);
                dirt = true;
            }
            return dirt;
        }

        public void store_xml(Xml.Node *node)
        {
            Xml.Node *brush = new Xml.Node(null,"brush");

            Xml.Node *red = new Xml.Node(null, "red");
            Xml.Node *blue = new Xml.Node(null, "blue");
            Xml.Node *green = new Xml.Node(null, "green");
            Xml.Node *alpha = new Xml.Node(null, "alpha");

            red->set_content("%u".printf(r));
            green->set_content("%u".printf(g));
            blue->set_content("%u".printf(b));
            alpha->set_content("%f".printf(a));

            brush->add_child(red);
            brush->add_child(blue);
            brush->add_child(green);
            brush->add_child(alpha);


            node->add_child(brush);
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
    while(length <25)
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
