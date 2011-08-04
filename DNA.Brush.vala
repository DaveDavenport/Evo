using GLib;
using Gdk;
using Xml;

namespace DNA
{

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
        public Brush.Random()
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
